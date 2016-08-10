/*
 * Authors:
 *  Landon Fuller <landonf@plausiblelabs.com>
 *  Damian Morris <damian@moso.com.au>
 *  Andreas Linde <mail@andreaslinde.de>
 *
 * Copyright (c) 2008-2013 Plausible Labs Cooperative, Inc.
 * Copyright (c) 2010 MOSO Corporation, Pty Ltd.
 * Copyright (c) 2012-2014 HockeyApp, Bit Stadium GmbH.
 * Copyright (c) 2015-16 Microsoft Corporation.
 *
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "AVAErrorLogFormatter.h"

#import <CrashReporter/CrashReporter.h>

#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <mach-o/ldsyms.h>
#import <dlfcn.h>
#import <Availability.h>

#if defined(__OBJC2__)
#define SEL_NAME_SECT "__objc_methname"
#else
#define SEL_NAME_SECT "__cstring"
#endif

#import "AVAErrorLog.h"
#import "AVAThread.h"
#import "AVAThreadFrame.h"
#import "AVABinary.h"

static NSString *unknownString = @"???";

/**
 * Sort PLCrashReportBinaryImageInfo instances by their starting address.
 */
static NSInteger bit_binaryImageSort(id binary1, id binary2, void *__unused context) {
  uint64_t addr1 = [binary1 imageBaseAddress];
  uint64_t addr2 = [binary2 imageBaseAddress];
  
  if (addr1 < addr2)
    return NSOrderedAscending;
  else if (addr1 > addr2)
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}

/**
 * Validates that the given @a string terminates prior to @a limit.
 */
static const char *safer_string_read (const char *string, const char *limit) {
  const char *p = string;
  do {
    if (p >= limit || p+1 >= limit) {
      return NULL;
    }
    p++;
  } while (*p != '\0');
  
  return string;
}

static NSString * formatted_address_matching_architecture (uint64_t address, BOOL is64bit) {
  return [NSString stringWithFormat:@"0x%0*" PRIx64, 8 << !!is64bit, address];
}

/*
 * The relativeAddress should be `<ecx/rsi/r1/x1 ...> - <image base>`, extracted from the crash report's thread
 * and binary image list.
 *
 * For the (architecture-specific) registers to attempt, see:
 *  http://sealiesoftware.com/blog/archive/2008/09/22/objc_explain_So_you_crashed_in_objc_msgSend.html
 */
static const char *findSEL (const char *imageName, NSString *imageUUID, uint64_t relativeAddress) {
  unsigned int images_count = _dyld_image_count();
  for (unsigned int i = 0; i < images_count; ++i) {
    intptr_t slide = _dyld_get_image_vmaddr_slide(i);
    const struct mach_header *header = _dyld_get_image_header(i);
    const struct mach_header_64 *header64 = (const struct mach_header_64 *) header;
    const char *name = _dyld_get_image_name(i);
    
    /* Image disappeared? */
    if (name == NULL || header == NULL)
      continue;
    
    /* Check if this is the correct image. If we were being even more careful, we'd check the LC_UUID */
    if (strcmp(name, imageName) != 0)
      continue;
    
    /* Determine whether this is a 64-bit or 32-bit Mach-O file */
    BOOL m64 = NO;
    if (header->magic == MH_MAGIC_64)
      m64 = YES;
    
    NSString *uuidString = nil;
    const uint8_t *command;
    uint32_t	ncmds;
    
    if (m64) {
      command = (const uint8_t *)(header64 + 1);
      ncmds = header64->ncmds;
    } else {
      command = (const uint8_t *)(header + 1);
      ncmds = header->ncmds;
    }
    for (uint32_t idx = 0; idx < ncmds; ++idx) {
      const struct load_command *load_command = (const struct load_command *)command;
      if (load_command->cmd == LC_UUID) {
        const struct uuid_command *uuid_command = (const struct uuid_command *)command;
        const uint8_t *uuid = uuid_command->uuid;
        uuidString = [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                       uuid[0], uuid[1], uuid[2], uuid[3],
                       uuid[4], uuid[5], uuid[6], uuid[7],
                       uuid[8], uuid[9], uuid[10], uuid[11],
                       uuid[12], uuid[13], uuid[14], uuid[15]]
                      lowercaseString];
        break;
      } else {
        command += load_command->cmdsize;
      }
    }
    
    // Check if this is the correct image by comparing the UUIDs
    if (!uuidString || ![uuidString isEqualToString:imageUUID])
      continue;
    
    /* Fetch the __objc_methname section */
    const char *methname_sect;
    uint64_t methname_sect_size;
    if (m64) {
      methname_sect = getsectdatafromheader_64(header64, SEG_TEXT, SEL_NAME_SECT, &methname_sect_size);
    } else {
      uint32_t meth_size_32;
      methname_sect = getsectdatafromheader(header, SEG_TEXT, SEL_NAME_SECT, &meth_size_32);
      methname_sect_size = meth_size_32;
    }
    
    /* Apply the slide, as per getsectdatafromheader(3) */
    methname_sect += slide;
    
    if (methname_sect == NULL) {
      return NULL;
    }
    
    /* Calculate the target address within this image, and verify that it is within __objc_methname */
    const char *target = ((const char *)header) + relativeAddress;
    const char *limit = methname_sect + methname_sect_size;
    if (target < methname_sect || target >= limit) {
      return NULL;
    }
    
    /* Read the actual method name */
    return safer_string_read(target, limit);
  }
  
  return NULL;
}


@implementation AVAErrorLogFormatter

NSString *const AVAXamarinStackTraceDelimiter = @"Xamarin Exception Stack:";

/**
 * Formats the provided report as human-readable text in the given @a textFormat, and return
 * the formatted result as a string.
 *
 * @param report The report to format.
 * @param textFormat The text format to use.
 *
 * @return Returns the formatted result on success, or nil if an error occurs.
 */
+ (AVAErrorLog *)errorLogFromCrashReport:(AVAPLCrashReport *)report {

  // Map to Apple-style code type, and mark whether architecture is LP64 (64-bit)
  NSNumber *codeType = [self extractCodeTypeFromReport:report];
  BOOL is64bit = [self isCodeType64bit:codeType];

  // Gather all addresses for which we need to preserve the binary image
  NSMutableArray *addresses = [NSMutableArray new];

  AVAPLCrashReportThreadInfo *crashedThread = nil;
  for (AVAPLCrashReportThreadInfo *thread in report.threads) {
    if (thread.crashed) {
      crashedThread = thread;
      break;
    }
  }
  
  AVAErrorLog *errorLog = [self errorLogFromCrashReport:report codeType:codeType is64bit:is64bit crashedThread:crashedThread];
  errorLog.threads = [self extractThreadsFromReport:report is64bit:is64bit addresses:&addresses];
  errorLog.binaries = [self extractBinaryImagesFromReport:report addresses:addresses codeType:codeType is64bit:is64bit];
  
  return errorLog;
}

+ (NSNumber *)extractCodeTypeFromReport:(const AVAPLCrashReport *)report {
  NSDictionary *legacyTypes = @{
                                @(PLCrashReportArchitectureARMv6): @(CPU_TYPE_ARM),
                                @(PLCrashReportArchitectureARMv7): @(CPU_TYPE_ARM),
                                @(PLCrashReportArchitectureX86_32): @(CPU_TYPE_X86),
                                @(PLCrashReportArchitectureX86_64): @(CPU_TYPE_X86_64),
                                @(PLCrashReportArchitecturePPC): @(CPU_TYPE_POWERPC),
                                };
  
  /* Attempt to derive the code type from the binary images */
  NSNumber *codeType = nil;
  for (AVAPLCrashReportBinaryImageInfo *image in report.images) {
    //TODO: (bereimol) use non-deprecated stuff
    //use this instead.
    //the NEW new schema will have fields for this
    //long cpuType = report.systemInfo.processorInfo.type;
//    long cpuSubType = report.systemInfo.processorInfo.subtype;
    codeType = @(image.codeType.type) ?:
    legacyTypes[@(report.systemInfo.architecture)] ?:
    [NSString stringWithFormat:@"Unknown (%d)",
     report.systemInfo.architecture];
    
    
    
    /* Stop immediately if code type was discovered */
    if (codeType != nil)
      break;
  }
  return codeType;
}

+ (BOOL)isCodeType64bit:(NSNumber *)codeType {
  NSDictionary *codeTypesAre64bit = @{
                                      @(CPU_TYPE_ARM): @NO,
                                      @(CPU_TYPE_ARM64): @YES,
                                      @(CPU_TYPE_X86): @NO,
                                      @(CPU_TYPE_X86_64): @YES,
                                      @(CPU_TYPE_POWERPC): @NO,
                                      };
  NSNumber *boolNumber = codeTypesAre64bit[codeType];
  return boolNumber.boolValue;
}

+ (NSArray *)extractThreadsFromReport:(AVAPLCrashReport *)report is64bit:(BOOL)is64bit addresses:(NSMutableArray **)addresses {
  NSMutableArray *formattedThreads = [NSMutableArray array];

  /* If an exception stack trace is available, output an Apple-compatible backtrace. */
  if (report.exceptionInfo != nil && report.exceptionInfo.stackFrames != nil && [report.exceptionInfo.stackFrames count] > 0) {
    AVAPLCrashReportExceptionInfo *exception = report.exceptionInfo;
    
    AVAThread *threadData = [AVAThread new];
    threadData.threadId = @(-1);

    
    /* Write out the frames. In raw reports, Apple writes this out as a simple list of PCs. In the minimally
     * post-processed report, Apple writes this out as full frame entries. We use the latter format. */
    for (AVAPLCrashReportStackFrameInfo *frameInfo in exception.stackFrames) {
      AVAThreadFrame *frame = [AVAThreadFrame new];
      frame.address = formatted_address_matching_architecture(frameInfo.instructionPointer, is64bit);
      [*addresses addObject:@(frameInfo.instructionPointer)];
      [threadData.frames addObject:frame];
    }
    [formattedThreads addObject:threadData];
  }

  /* Threads */
  for (AVAPLCrashReportThreadInfo *thread in report.threads) {
    AVAThread *threadData = [AVAThread new];
    threadData.threadId = @(thread.threadNumber);

    for (AVAPLCrashReportStackFrameInfo *frameInfo in thread.stackFrames) {
      AVAThreadFrame *frame = [AVAThreadFrame new];
      frame.address = formatted_address_matching_architecture(frameInfo.instructionPointer, is64bit);
      [*addresses addObject:@(frameInfo.instructionPointer)];
      [threadData.frames addObject:frame];
    }

    /* Registers */
    if (thread.crashed) {
      
      for (AVAPLCrashReportRegisterInfo *registerInfo in thread.registers) {
        NSString *regName = registerInfo.registerName;

        // Currently we only need "lr"
        if([regName isEqualToString:@"lr"]){
          NSString *formattedRegName = [NSString stringWithFormat:@"%s", [regName UTF8String]];
          NSString *formattedRegValue = @"";

          formattedRegValue = formatted_address_matching_architecture(registerInfo.registerValue, is64bit);

          if (threadData.frames.count > 0) {
            AVAThreadFrame *threadFrame = threadData.frames[0];
            threadFrame.registers = @{formattedRegName: formattedRegValue};
            [*addresses addObject:@(registerInfo.registerValue)];
          }
          break;
        }
      }
    }
    [formattedThreads addObject:threadData];
  }
  return formattedThreads;
}


+ (AVAErrorLog *)errorLogFromCrashReport:(AVAPLCrashReport *)report codeType:(NSNumber *)codeType is64bit:(boolean_t)is64bit crashedThread:(AVAPLCrashReportThreadInfo *)crashedThread {
  AVAErrorLog *errorLog = [AVAErrorLog new];
  /* Application and process info */
  {
    errorLog.crashId = report.uuidRef ? (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, report.uuidRef)) : unknownString;
    
    //TODO: (bereimol) ApplicationIdentifier aka CFBundleIdentifier is missing, don't need anymore?
//    crashHeaders.applicationIdentifier = report.applicationInfo.applicationIdentifier;
    
    //TODO: (bereimol) ApplicationVersion aka CFBundleVersion is missing, don't need anymore?
//    crashHeaders.applicationBuild = report.applicationInfo.applicationVersion;
    
    errorLog.process = unknownString;
    errorLog.processId = nil;
    errorLog.parentProcess = unknownString;
    errorLog.parentProcessId = nil;
    errorLog.applicationPath = unknownString;
    
    //Process information was not available in earlier crash report versions
    if (report.hasProcessInfo) {
      //Process Name
      errorLog.process = report.processInfo.processName ?: errorLog.process;
      
      //PID
      errorLog.processId = @(report.processInfo.processID);
      
      /* Process Path */
      if (report.processInfo.processPath != nil) {
        NSString *processPath = report.processInfo.processPath;
        
        /* Remove username from the path */
#if TARGET_OS_SIMULATOR
        processPath = [self anonymizedProcessPathFromProcessPath:processPath];
#endif
        errorLog.applicationPath = processPath;
      }
      
      /* Parent Process Name */
      if (report.processInfo.parentProcessName != nil) {
        errorLog.parentProcess = report.processInfo.parentProcessName;
      }
      /* Parent Process ID */
      errorLog.parentProcessId = @(report.processInfo.parentProcessID);
    }
  }
  
  /* Exception code */
  errorLog.exceptionAddress = [NSString stringWithFormat:@"0x%" PRIx64, report.signalInfo.address];
  errorLog.exceptionCode = report.signalInfo.code;
  errorLog.exceptionReason = nil;
  errorLog.exceptionType = report.signalInfo.name;
  
  errorLog.crashThread = @(crashedThread.threadNumber);
  
  /* Uncaught Exception */
  if (report.hasExceptionInfo) {
    errorLog.exceptionReason = [NSString stringWithFormat:@"*** Terminating app due to uncaught exception %@: %@", report.exceptionInfo.exceptionName, report.exceptionInfo.exceptionReason];
    
    //TODO: (bereimol) check if this still works for XamarinSDK
    
    // Check if exception data contains xamarin stacktrace in order to determine report version
    if (report.hasExceptionInfo) {
      NSString *xamarinTrace;
      NSString *exceptionReason;
      
      exceptionReason = report.exceptionInfo.exceptionReason;
      NSInteger xamarinTracePosition = [exceptionReason rangeOfString:AVAXamarinStackTraceDelimiter].location;
      if (xamarinTracePosition != NSNotFound) {
        xamarinTrace = [exceptionReason substringFromIndex:xamarinTracePosition];
        xamarinTrace = [xamarinTrace stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        xamarinTrace = [xamarinTrace stringByReplacingOccurrencesOfString:@"<---\n\n--->" withString:@"<---\n--->"];
        exceptionReason = [exceptionReason substringToIndex:xamarinTracePosition];
        exceptionReason = [exceptionReason stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      }
    }
    
  } else if (crashedThread != nil) {
    // try to find the selector in case this was a crash in obj_msgSend
    // we search this whether the crash happened in obj_msgSend or not since we don't have the symbol!
    
    NSString *foundSelector = nil;
    
    // search the registers value for the current arch
#if TARGET_OS_SIMULATOR
    if (is64bit) {
      foundSelector = [[self class] selectorForRegisterWithName:@"rsi" ofThread:crashedThread report:report];
      if (foundSelector == NULL)
        foundSelector = [[self class] selectorForRegisterWithName:@"rdx" ofThread:crashedThread report:report];
    } else {
      foundSelector = [[self class] selectorForRegisterWithName:@"ecx" ofThread:crashedThread report:report];
    }
#else
    if (is64bit) {
      foundSelector = [[self class] selectorForRegisterWithName:@"x1" ofThread:crashedThread report:report];
    } else {
      foundSelector = [[self class] selectorForRegisterWithName:@"r1" ofThread:crashedThread report:report];
      if (foundSelector == NULL)
        foundSelector = [[self class] selectorForRegisterWithName:@"r2" ofThread:crashedThread report:report];
    }
#endif
    
    if (foundSelector) {
      errorLog.exceptionReason = [NSString stringWithFormat:@"Selector name found in current argument registers: %@\n", foundSelector];
    }
  }
  return errorLog;
}

+ (NSArray *)extractBinaryImagesFromReport:(AVAPLCrashReport *)report addresses:(NSArray *)addresses codeType:(NSNumber *)codeType is64bit:(boolean_t)is64bit {
  NSMutableArray *binaryImages = [NSMutableArray array];
  /* Images. The iPhone crash report format sorts these in ascending order, by the base address */
  for (AVAPLCrashReportBinaryImageInfo *imageInfo in [report.images sortedArrayUsingFunction: bit_binaryImageSort context: nil]) {
    AVABinary *binary = [AVABinary new];
    
    binary.binaryId = (imageInfo.hasImageUUID) ? imageInfo.imageUUID : unknownString;
    
    uint64_t startAddress = imageInfo.imageBaseAddress;
    binary.startAddress = formatted_address_matching_architecture(startAddress, is64bit);
    
    uint64_t endAddress = imageInfo.imageBaseAddress + (MAX((uint64_t)1, imageInfo.imageSize) - 1);
    binary.endAddress = formatted_address_matching_architecture(endAddress, is64bit);
    
    BOOL binaryIsInAddresses = [self isBinaryWithStart:startAddress end:endAddress inAddresses:addresses];
    AVABinaryImageType imageType = [self imageTypeForImagePath:imageInfo.imageName processPath:report.processInfo.processPath];
    
    if (binaryIsInAddresses || (imageType != AVABinaryImageTypeOther)) {
      
      /* Remove username from the image path */
      NSString *imageName = @"";
      if (imageInfo.imageName && [imageInfo.imageName length] > 0) {
#if TARGET_IPHONE_SIMULATOR
        imageName = [imageInfo.imageName stringByAbbreviatingWithTildeInPath];
#else
        imageName = imageInfo.imageName;
#endif
      }
#if TARGET_IPHONE_SIMULATOR
      if ([imageName length] > 0 && [[imageName substringToIndex:1] isEqualToString:@"~"]) {
        imageName = [NSString stringWithFormat:@"/Users/USER%@", [imageName substringFromIndex:1]];
      }
#endif
      
      binary.path = imageName;
      binary.name = [imageInfo.imageName lastPathComponent];
      
      /* Fetch the UUID if it exists */
      binary.binaryId = (imageInfo.hasImageUUID) ? imageInfo.imageUUID : unknownString;
      
      //TODO: (bereimol) add CPU arch
      
      /* Determine the architecture string */
//      binary.cpuType = codeType;
//      binary.cpuSubType = @(imageInfo.codeType.subtype);
      
      [binaryImages addObject:binary];
    }
  }
  return binaryImages;
}

+ (BOOL)isBinaryWithStart:(uint64_t)start end:(uint64_t)end inAddresses:(NSArray *)addresses{
  for(NSNumber *address in addresses){
    
    if([address unsignedLongLongValue] >= start && [address unsignedLongLongValue] <= end){
      return YES;
    }
  }
  return NO;
}

/**
 *  Remove the user's name from a crash's process path.
 *  This is only necessary when sending crashes from the simulator as the path
 *  then contains the username of the Mac the simulator is running on.
 *
 *  @param processPath A string containing the username
 *
 *  @return An anonymized string where the real username is replaced by "USER"
 */
+ (NSString *)anonymizedProcessPathFromProcessPath:(NSString *)processPath {
  
  NSString *anonymizedProcessPath = [NSString string];
  
  if (([processPath length] > 0) && [processPath hasPrefix:@"/Users/"]) {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(/Users/[^/]+/)" options:0 error:&error];
    anonymizedProcessPath = [regex stringByReplacingMatchesInString:processPath options:0 range:NSMakeRange(0, [processPath length]) withTemplate:@"/Users/USER/"];
    if (error) {
      AVALogError(@"ERROR: String replacing failed - %@", error.localizedDescription);
    }
  }
  return anonymizedProcessPath;
}

//**
//*  Return the selector string of a given register name
//*
//*  @param regName The name of the register to use for getting the address
//*  @param thread  The crashed thread
//*  @param images  NSArray of binary images
//*
//*  @return The selector as a C string or NULL if no selector was found
//*/
+ (NSString *)selectorForRegisterWithName:(NSString *)regName ofThread:(AVAPLCrashReportThreadInfo *)thread report:(AVAPLCrashReport *)report {
  // get the address for the register
  uint64_t regAddress = 0;
  
  for (AVAPLCrashReportRegisterInfo *reg in thread.registers) {
    if ([reg.registerName isEqualToString:regName]) {
      regAddress = reg.registerValue;
      break;
    }
  }
  
  if (regAddress == 0)
    return nil;
  
  AVAPLCrashReportBinaryImageInfo *imageForRegAddress = [report imageForAddress:regAddress];
  if (imageForRegAddress) {
    // get the SEL
    const char *foundSelector = findSEL([imageForRegAddress.imageName UTF8String], imageForRegAddress.imageUUID, regAddress - (uint64_t)imageForRegAddress.imageBaseAddress);
    
    if (foundSelector != NULL) {
      return [NSString stringWithUTF8String:foundSelector];
    }
  }
  
  return nil;
}

/* Determine if in binary image is the app executable or app specific framework */
+ (AVABinaryImageType)imageTypeForImagePath:(NSString *)imagePath processPath:(NSString *)processPath {
  AVABinaryImageType imageType = AVABinaryImageTypeOther;
  
  NSString *standardizedImagePath = [[imagePath stringByStandardizingPath] lowercaseString];
  imagePath = [imagePath lowercaseString];
  processPath = [processPath lowercaseString];
  
  NSRange appRange = [standardizedImagePath rangeOfString: @".app/"];
  
  // Exclude iOS swift dylibs. These are provided as part of the app binary by Xcode for now, but we never get a dSYM for those.
  NSRange swiftLibRange = [standardizedImagePath rangeOfString:@"frameworks/libswift"];
  BOOL dylibSuffix = [standardizedImagePath hasSuffix:@".dylib"];
  
  if (appRange.location != NSNotFound && !(swiftLibRange.location != NSNotFound && dylibSuffix)) {
    NSString *appBundleContentsPath = [standardizedImagePath substringToIndex:appRange.location + 5];
    
    if ([standardizedImagePath isEqual: processPath] ||
        // Fix issue with iOS 8 `stringByStandardizingPath` removing leading `/private` path (when not running in the debugger or simulator only)
        [imagePath hasPrefix:processPath]) {
      imageType = AVABinaryImageTypeAppBinary;
    } else if ([standardizedImagePath hasPrefix:appBundleContentsPath] ||
               // Fix issue with iOS 8 `stringByStandardizingPath` removing leading `/private` path (when not running in the debugger or simulator only)
               [imagePath hasPrefix:appBundleContentsPath]) {
      imageType = AVABinaryImageTypeAppFramework;
    }
  }
  
  return imageType;
}



@end
