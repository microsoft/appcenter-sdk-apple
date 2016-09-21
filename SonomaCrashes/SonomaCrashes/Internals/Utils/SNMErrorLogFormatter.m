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

#import "SNMErrorLogFormatter.h"

#import "SNMCrashesPrivate.h"
#import <CrashReporter/CrashReporter.h>

#import <Availability.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <mach-o/ldsyms.h>

#if defined(__OBJC2__)
#define SEL_NAME_SECT "__objc_methname"
#else
#define SEL_NAME_SECT "__cstring"
#endif

#import "SNMAppleErrorLog.h"
#import "SNMBinary.h"
#import "SNMException.h"
#import "SNMStackFrame.h"
#import "SNMThread.h"
#import "SNMErrorReport.h"
#import "SNMErrorReportPrivate.h"
#import "SNMSonomaInternal.h"


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
static const char *safer_string_read(const char *string, const char *limit) {
  const char *p = string;
  do {
    if (p >= limit || p + 1 >= limit) {
      return NULL;
    }
    p++;
  } while (*p != '\0');

  return string;
}

static NSString *formatted_address_matching_architecture(uint64_t address, BOOL is64bit) {
  return [NSString stringWithFormat:@"0x%0*" PRIx64, 8 << !!is64bit, address];
}

/*
 * The relativeAddress should be `<ecx/rsi/r1/x1 ...> - <image base>`, extracted
 * from the crash report's thread
 * and binary image list.
 *
 * For the (architecture-specific) registers to attempt, see:
 *  http://sealiesoftware.com/blog/archive/2008/09/22/objc_explain_So_you_crashed_in_objc_msgSend.html
 */
static const char *findSEL(const char *imageName, NSString *imageUUID, uint64_t relativeAddress) {
  unsigned int images_count = _dyld_image_count();
  for (unsigned int i = 0; i < images_count; ++i) {
    intptr_t slide = _dyld_get_image_vmaddr_slide(i);
    const struct mach_header *header = _dyld_get_image_header(i);
    const struct mach_header_64 *header64 = (const struct mach_header_64 *)header;
    const char *name = _dyld_get_image_name(i);

    /* Image disappeared? */
    if (name == NULL || header == NULL)
      continue;

    /* Check if this is the correct image. If we were being even more careful,
     * we'd check the LC_UUID */
    if (strcmp(name, imageName) != 0)
      continue;

    /* Determine whether this is a 64-bit or 32-bit Mach-O file */
    BOOL m64 = NO;
    if (header->magic == MH_MAGIC_64)
      m64 = YES;

    NSString *uuidString = nil;
    const uint8_t *command;
    uint32_t ncmds;

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
        uuidString = [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%"
                                                 @"02X%02X%02X%02X%02X",
                                                 uuid[0], uuid[1], uuid[2], uuid[3], uuid[4], uuid[5], uuid[6], uuid[7],
                                                 uuid[8], uuid[9], uuid[10], uuid[11], uuid[12], uuid[13], uuid[14],
                                                 uuid[15]] lowercaseString];
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

    /* Calculate the target address within this image, and verify that it is
     * within __objc_methname */
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

@implementation SNMErrorLogFormatter

NSString *const SNMXamarinStackTraceDelimiter = @"Xamarin Exception Stack:";

/**
 * Formats the provided report as human-readable text in the given @a
 * textFormat, and return
 * the formatted result as a string.
 *
 * @param report The report to format.
 * @param textFormat The text format to use.
 *
 * @return Returns the formatted result on success, or nil if an error occurs.
 */
+ (SNMAppleErrorLog *)errorLogFromCrashReport:(SNMPLCrashReport *)report {

  // Map to Apple-style code type, and mark whether architecture is LP64
  // (64-bit)
  NSNumber *codeType = [self extractCodeTypeFromReport:report];
  BOOL is64bit = [self isCodeType64bit:codeType];

  // Gather all addresses for which we need to preserve the binary image
  NSMutableArray *addresses = [NSMutableArray new];

  SNMPLCrashReportThreadInfo *crashedThread = nil;
  for (SNMPLCrashReportThreadInfo *thread in report.threads) {
    if (thread.crashed) {
      crashedThread = thread;
      break;
    }
  }

  SNMAppleErrorLog *errorLog =
      [self errorLogFromCrashReport:report codeType:codeType is64bit:is64bit crashedThread:crashedThread];
  errorLog.threads = [self extractThreadsFromReport:report is64bit:is64bit addresses:&addresses];
  errorLog.binaries = [self extractBinaryImagesFromReport:report addresses:addresses codeType:codeType is64bit:is64bit];

  return errorLog;
}


+ (SNMErrorReport *)createErrorReportFrom:(SNMPLCrashReport *)report {
  if(!report) {
    return nil;
  }
  
  SNMErrorReport *errorReport = nil;
  
  NSString *incidentIdentifier = @"???";
  if (report.uuidRef != NULL) {
    incidentIdentifier = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, report.uuidRef));
  }
  
  // There should always be an installId. Leaving the empty string out of paranoia
  // as [UUID UUID] – used in [SNMSonoma installId] might, in theory, return nil.
  NSString *reporterKey = [[SNMSonoma installId] UUIDString] ?: @"";
  
  NSString *signal = report.signalInfo.name;
  NSString *exceptionName = report.exceptionInfo.exceptionName;
  NSString *exceptionReason = report.exceptionInfo.exceptionReason;
  
  NSDate *appStartTime = nil;
  NSDate *crashTime = nil;
  if ([report.processInfo respondsToSelector:@selector(processStartTime)]) {
    if (report.systemInfo.timestamp && report.processInfo.processStartTime) {
      appStartTime = report.processInfo.processStartTime;
      crashTime = report.systemInfo.timestamp;
    }
  }
  
  NSString *osVersion = report.systemInfo.operatingSystemVersion;
  NSString *osBuild = report.systemInfo.operatingSystemBuild;
  NSString *appVersion = report.applicationInfo.applicationMarketingVersion;
  NSString *appBuild = report.applicationInfo.applicationVersion;
  NSUInteger processId = report.processInfo.processID;
  
  errorReport = [[SNMErrorReport alloc] initWithIncidentIdentifier:incidentIdentifier
                                                       reporterKey:reporterKey
                                                            signal:signal
                                                     exceptionName:exceptionName
                                                   exceptionReason:exceptionReason
                                                      appStartTime:appStartTime
                                                         crashTime:crashTime
                                                         osVersion:osVersion
                                                           osBuild:osBuild
                                                        appVersion:appVersion
                                                          appBuild:appBuild
                                              appProcessIdentifier:processId];
  
  return errorReport;
}

+ (NSNumber *)extractCodeTypeFromReport:(const SNMPLCrashReport *)report {
  NSDictionary *legacyTypes = @{
    @(PLCrashReportArchitectureARMv6) : @(CPU_TYPE_ARM),
    @(PLCrashReportArchitectureARMv7) : @(CPU_TYPE_ARM),
    @(PLCrashReportArchitectureX86_32) : @(CPU_TYPE_X86),
    @(PLCrashReportArchitectureX86_64) : @(CPU_TYPE_X86_64),
    @(PLCrashReportArchitecturePPC) : @(CPU_TYPE_POWERPC),
  };
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  /* Attempt to derive the code type from the binary images */
  NSNumber *codeType = nil;
  for (SNMPLCrashReportBinaryImageInfo *image in report.images) {
    codeType =
    @(image.codeType.type) ?: @(report.systemInfo.processorInfo.type) ?: legacyTypes[@(report.systemInfo.architecture)]
                                      ?: [NSString stringWithFormat:@"Unknown (%d)", report.systemInfo.architecture];

    /* Stop immediately if code type was discovered */
    if (codeType != nil)
      break;
  }
#pragma GCC diagnostic pop
  return codeType;
}

+ (BOOL)isCodeType64bit:(NSNumber *)codeType {
  NSDictionary *codeTypesAre64bit = @{
    @(CPU_TYPE_ARM) : @NO,
    @(CPU_TYPE_ARM64) : @YES,
    @(CPU_TYPE_X86) : @NO,
    @(CPU_TYPE_X86_64) : @YES,
    @(CPU_TYPE_POWERPC) : @NO,
  };
  NSNumber *boolNumber = codeTypesAre64bit[codeType];
  return boolNumber.boolValue;
}

+ (NSArray<SNMThread *> *)extractThreadsFromReport:(SNMPLCrashReport *)report
                                                is64bit:(BOOL)is64bit
                                              addresses:(NSMutableArray **)addresses {
  NSMutableArray<SNMThread *> *formattedThreads = [NSMutableArray array];

  /* If an exception stack trace is available, output an Apple-compatible
   * backtrace. */
  if (report.exceptionInfo != nil && report.exceptionInfo.stackFrames != nil &&
      [report.exceptionInfo.stackFrames count] > 0) {
    SNMPLCrashReportExceptionInfo *exception = report.exceptionInfo;

    // TODO: move stackframe parsing for an exception somewhere else, maybe to the errorLog generation?!

    SNMThread *exceptionThread = [SNMThread new];
    exceptionThread.threadId = @(-1);

    /* Write out the frames. In raw reports, Apple writes this out as a simple
     * list of PCs. In the minimally
     * post-processed report, Apple writes this out as full frame entries. We
     * use the latter format. */
    for (SNMPLCrashReportStackFrameInfo *frameInfo in exception.stackFrames) {
      SNMStackFrame *frame = [SNMStackFrame new];
      frame.address = formatted_address_matching_architecture(frameInfo.instructionPointer, is64bit);

      // TODO we're mutating the addresses-Object again here
      [*addresses addObject:@(frameInfo.instructionPointer)];

      [exceptionThread.frames addObject:frame];
    }

    SNMException *lastException = [SNMException new];
    lastException.message = exception.exceptionReason;
    lastException.frames = exceptionThread.frames;

    lastException.type = report.exceptionInfo.exceptionName ?: report.signalInfo.name;
    // TODO what about an "exceptionCode"?
    //    errorLog.osExceptionCode = report.signalInfo.code;
    exceptionThread.exception = lastException;

    // Don't forget to add the thread to the array of threads!
    [formattedThreads addObject:exceptionThread];

    // TODO add AppleException to ErrorLog?!
  }

  /* Threads */
  for (SNMPLCrashReportThreadInfo *thread in report.threads) {
    SNMThread *threadData = [SNMThread new];
    threadData.threadId = @(thread.threadNumber);

    // TODO frames are missing in crash logs but it is a required field.
    
    for (SNMPLCrashReportStackFrameInfo *frameInfo in thread.stackFrames) {
      SNMStackFrame *frame = [SNMStackFrame new];
      frame.address = formatted_address_matching_architecture(frameInfo.instructionPointer, is64bit);
      [*addresses addObject:@(frameInfo.instructionPointer)];
      [threadData.frames addObject:frame];
    }

    /* Registers */
    if (thread.crashed) {

      for (SNMPLCrashReportRegisterInfo *registerInfo in thread.registers) {
        NSString *regName = registerInfo.registerName;

        // Currently we only need "lr"
        // TODO check if we still only need the LR register
        if ([regName isEqualToString:@"lr"]) {
          NSString *formattedRegName = [NSString stringWithFormat:@"%s", [regName UTF8String]];
          NSString *formattedRegValue = @"";

          formattedRegValue = formatted_address_matching_architecture(registerInfo.registerValue, is64bit);

          if (threadData.frames.count > 0) {
            SNMStackFrame *stackFrame = threadData.frames[0];
            stackFrame.address = formattedRegValue;
            stackFrame.code = formattedRegName;
            // TODO check with Andreas and Gwynne if that's correct.
            // Hockey used to have this:
            //                      stackFrame.registers = @{formattedRegName : formattedRegValue};
            // TODO this is actually pretty bad. The method mutates the list of addresses but this is nowhere
            // documented and we should make this more obvious.
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

+ (SNMAppleErrorLog *)errorLogFromCrashReport:(SNMPLCrashReport *)report
                                     codeType:(NSNumber *)codeType
                                      is64bit:(boolean_t)is64bit
                                crashedThread:(SNMPLCrashReportThreadInfo *)crashedThread {

  SNMAppleErrorLog *errorLog = [SNMAppleErrorLog new];

  // Application Path and process info
  errorLog.errorId =
      report.uuidRef ? (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, report.uuidRef)) : unknownString;

  errorLog = [self extractProcessInformation:errorLog fromCrashReport:report];

  // Error Thread Info.
  errorLog.errorThreadId = @(crashedThread.threadNumber);

  // errorLog.errorThreadName won't be used on iOS right now, will be relevant for handled exceptions.

  // All errors are fatal for now, until we add support for handled exceptions.
  errorLog.fatal = YES;

  // appLaunchTOffset - the difference between crashtime and initialization time, so the "age" of the crashreport before
  // it's forwarded to the channel.
  // We don't care about a negative difference (will happen if the user's time on the device changes to a time before
  // the crashTime and the time the error is processed.
  NSDate *crashTime = report.systemInfo.timestamp;
  NSDate *initializationDate = [[SNMCrashes sharedInstance] initializationDate];
  NSTimeInterval difference = [initializationDate timeIntervalSinceDate:crashTime];
  errorLog.appLaunchTOffset = @(difference);

  // CPU Type and Subtype
  // TODO errorLog.architecture is an optional but might need to assign a string. It might be able to be deleted (requires schema update).
  errorLog.primaryArchitectureId = @(report.systemInfo.processorInfo.type);
  errorLog.architectureVariantId = @(report.systemInfo.processorInfo.subtype);

  /* Exception code */

  // TODO: Check this during testing/crashprobe
  // HockeyApp didn't use report.exceptionInfo for this field but exception.name in case of an unhandled exception or
  // the report.signalInfo.name
  // more so, for BITCrashDetails, we used the exceptionInfo.exceptionName for a field called exceptionName. FYI: Gwynne
  // has no idea. Andreas will be next ;)
  errorLog.osExceptionType = report.exceptionInfo.exceptionName ?: report.signalInfo.name;

  errorLog.osExceptionCode = report.signalInfo.code; // TODO check with Andreas/Gwynne

  errorLog.osExceptionAddress =
      [NSString stringWithFormat:@"0x%" PRIx64, report.signalInfo.address]; // TODO check with Andreas

  // TODO Check this during testing, too.
  // Same as above, HA didn't use report.exceptionInfo.exceptionReason but a handled exception
  errorLog.exceptionReason = report.exceptionInfo.exceptionReason ?: nil;
  errorLog.exceptionReason = nil;
  errorLog.exceptionType = report.signalInfo.name;

  /* Uncaught Exception */
  if (report.hasExceptionInfo) {
    errorLog.exceptionReason =
        [NSString stringWithFormat:@"*** Terminating app due to uncaught exception %@: %@",
                                   report.exceptionInfo.exceptionName, report.exceptionInfo.exceptionReason];

    // TODO: Change to new Xamarin Schema.

    // Check if exception data contains xamarin stacktrace in order to determine
    // report version
    if (report.hasExceptionInfo) {
      NSString *xamarinTrace;
      NSString *exceptionReason;

      exceptionReason = report.exceptionInfo.exceptionReason;
      NSInteger xamarinTracePosition = [exceptionReason rangeOfString:SNMXamarinStackTraceDelimiter].location;
      if (xamarinTracePosition != NSNotFound) {
        xamarinTrace = [exceptionReason substringFromIndex:xamarinTracePosition];
        xamarinTrace = [xamarinTrace stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        xamarinTrace = [xamarinTrace stringByReplacingOccurrencesOfString:@"<---\n\n--->" withString:@"<---\n--->"];
        exceptionReason = [exceptionReason substringToIndex:xamarinTracePosition];
        exceptionReason =
            [exceptionReason stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      }
    }

  } else if (crashedThread != nil) {
    // try to find the selector in case this was a crash in obj_msgSend
    // we search this whether the crash happened in obj_msgSend or not since we
    // don't have the symbol!

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
      errorLog.exceptionReason =
          [NSString stringWithFormat:@"Selector name found in current argument registers: %@\n", foundSelector];
    }
  }
  return errorLog;
}

+ (SNMAppleErrorLog *)extractProcessInformation:(SNMAppleErrorLog *)errorLog
                                fromCrashReport:(SNMPLCrashReport *)crashReport {
  // Set the defaults first.
  errorLog.processId = nil; //TODO check with schema, andreas and stefan
  errorLog.processName = unknownString;
  errorLog.parentProcessName = unknownString;
  errorLog.parentProcessId = nil;
  errorLog.applicationPath = unknownString;

  // Convert SNMPLCrashReport process information.
  if (crashReport.hasProcessInfo) {
    errorLog.processId = @(crashReport.processInfo.processID);
    errorLog.processName = crashReport.processInfo.processName ?: errorLog.processName;

    /* Process Path */
    if (crashReport.processInfo.processPath != nil) {
      NSString *processPath = crashReport.processInfo.processPath;

// Remove username from the path
#if TARGET_OS_SIMULATOR
      processPath = [self anonymizedPathFromPath:processPath];
#endif
      errorLog.applicationPath = processPath;
    }

    // Parent Process Name
    if (crashReport.processInfo.parentProcessName != nil) {
      errorLog.parentProcessName = crashReport.processInfo.parentProcessName;
    }
    // Parent Process ID
    errorLog.parentProcessId = @(crashReport.processInfo.parentProcessID);
  }
  return errorLog;
}

+ (NSArray<SNMBinary *> *)extractBinaryImagesFromReport:(SNMPLCrashReport *)report
                                                   addresses:(NSArray *)addresses
                                                    codeType:(NSNumber *)codeType
                                                     is64bit:(boolean_t)is64bit {
  NSMutableArray<SNMBinary *> *binaryImages = [NSMutableArray array];
  /* Images. The iPhone crash report format sorts these in ascending order, by
   * the base address */
  for (SNMPLCrashReportBinaryImageInfo *imageInfo in
       [report.images sortedArrayUsingFunction:bit_binaryImageSort context:nil]) {
    SNMBinary *binary = [SNMBinary new];

    binary.binaryId = (imageInfo.hasImageUUID) ? imageInfo.imageUUID : unknownString;

    uint64_t startAddress = imageInfo.imageBaseAddress;
    binary.startAddress = formatted_address_matching_architecture(startAddress, is64bit);

    uint64_t endAddress = imageInfo.imageBaseAddress + (MAX((uint64_t)1, imageInfo.imageSize) - 1);
    binary.endAddress = formatted_address_matching_architecture(endAddress, is64bit);

    BOOL binaryIsInAddresses = [self isBinaryWithStart:startAddress end:endAddress inAddresses:addresses];
    SNMBinaryImageType imageType =
        [self imageTypeForImagePath:imageInfo.imageName processPath:report.processInfo.processPath];

    if (binaryIsInAddresses || (imageType != SNMBinaryImageTypeOther)) {

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
      imageName = [self anonymizedPathFromPath: imageName];
#endif

      binary.path = imageName;
      binary.name = [imageInfo.imageName lastPathComponent];

      /* Fetch the UUID if it exists */
      binary.binaryId = (imageInfo.hasImageUUID) ? imageInfo.imageUUID : unknownString;
      /* Determine the architecture string */
      // TODO binary.architecture already exists in AbstractErrorLog. Can be deleted (requires schema update) ?
      binary.primaryArchitectureId = codeType;
      binary.architectureVariantId = @(imageInfo.codeType.subtype);

      [binaryImages addObject:binary];
    }
  }
  return binaryImages;
}

+ (BOOL)isBinaryWithStart:(uint64_t)start end:(uint64_t)end inAddresses:(NSArray *)addresses {
  for (NSNumber *address in addresses) {

    if ([address unsignedLongLongValue] >= start && [address unsignedLongLongValue] <= end) {
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
+ (NSString *)anonymizedPathFromPath:(NSString *)processPath {

  NSString *anonymizedProcessPath = [NSString string];

  if (([processPath length] > 0) && [processPath hasPrefix:@"/Users/"]) {
    NSError *error = nil;
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:@"(/Users/[^/]+/)" options:0 error:&error];
    anonymizedProcessPath = [regex stringByReplacingMatchesInString:processPath
                                                            options:0
                                                              range:NSMakeRange(0, [processPath length])
                                                       withTemplate:@"/Users/USER/"];
    if (error) {
      SNMLogError(@"ERROR: String replacing failed - %@", error.localizedDescription);
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
+ (NSString *)selectorForRegisterWithName:(NSString *)regName
                                 ofThread:(SNMPLCrashReportThreadInfo *)thread
                                   report:(SNMPLCrashReport *)report {
  // get the address for the register
  uint64_t regAddress = 0;

  for (SNMPLCrashReportRegisterInfo *reg in thread.registers) {
    if ([reg.registerName isEqualToString:regName]) {
      regAddress = reg.registerValue;
      break;
    }
  }

  if (regAddress == 0)
    return nil;

  SNMPLCrashReportBinaryImageInfo *imageForRegAddress = [report imageForAddress:regAddress];
  if (imageForRegAddress) {
    // get the SEL
    const char *foundSelector = findSEL([imageForRegAddress.imageName UTF8String], imageForRegAddress.imageUUID,
                                        regAddress - (uint64_t)imageForRegAddress.imageBaseAddress);

    if (foundSelector != NULL) {
      return [NSString stringWithUTF8String:foundSelector];
    }
  }

  return nil;
}

/* Determine if in binary image is the app executable or app specific framework
 */
+ (SNMBinaryImageType)imageTypeForImagePath:(NSString *)imagePath processPath:(NSString *)processPath {
  SNMBinaryImageType imageType = SNMBinaryImageTypeOther;

  NSString *standardizedImagePath = [[imagePath stringByStandardizingPath] lowercaseString];
  imagePath = [imagePath lowercaseString];
  processPath = [processPath lowercaseString];

  NSRange appRange = [standardizedImagePath rangeOfString:@".app/"];

  // Exclude iOS swift dylibs. These are provided as part of the app binary by
  // Xcode for now, but we never get a dSYM for those.
  NSRange swiftLibRange = [standardizedImagePath rangeOfString:@"frameworks/libswift"];
  BOOL dylibSuffix = [standardizedImagePath hasSuffix:@".dylib"];

  if (appRange.location != NSNotFound && !(swiftLibRange.location != NSNotFound && dylibSuffix)) {
    NSString *appBundleContentsPath = [standardizedImagePath substringToIndex:appRange.location + 5];

    if ([standardizedImagePath isEqual:processPath] ||
        // Fix issue with iOS 8 `stringByStandardizingPath` removing leading
        // `/private` path (when not running in the debugger or simulator only)
        [imagePath hasPrefix:processPath]) {
      imageType = SNMBinaryImageTypeAppBinary;
    } else if ([standardizedImagePath hasPrefix:appBundleContentsPath] ||
               // Fix issue with iOS 8 `stringByStandardizingPath` removing
               // leading `/private` path (when not running in the debugger or
               // simulator only)
               [imagePath hasPrefix:appBundleContentsPath]) {
      imageType = SNMBinaryImageTypeAppFramework;
    }
  }

  return imageType;
}

@end
