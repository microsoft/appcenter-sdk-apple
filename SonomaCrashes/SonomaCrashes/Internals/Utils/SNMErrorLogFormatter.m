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

#import <CrashReporter/CrashReporter.h>
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
#import "SNMCrashesPrivate.h"
#import "SNMErrorLogFormatter.h"
#import "SNMErrorReport.h"
#import "SNMErrorReportPrivate.h"
#import "SNMException.h"
#import "MSSonomaInternal.h"
#import "SNMStackFrame.h"
#import "SNMThread.h"
#import "MSDeviceTracker.h"

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
    const struct mach_header_64 *header64 = (const struct mach_header_64 *) header;
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
      command = (const uint8_t *) (header64 + 1);
      ncmds = header64->ncmds;
    } else {
      command = (const uint8_t *) (header + 1);
      ncmds = header->ncmds;
    }
    for (uint32_t idx = 0; idx < ncmds; ++idx) {
      const struct load_command *load_command = (const struct load_command *) command;
      if (load_command->cmd == LC_UUID) {
        const struct uuid_command *uuid_command = (const struct uuid_command *) command;
        const uint8_t *uuid = uuid_command->uuid;
        uuidString = [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%"
                                                     @
                                                     "02X%02X%02X%02X%02X",
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
    const char *target = ((const char *) header) + relativeAddress;
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

  SNMAppleErrorLog *errorLog = [SNMAppleErrorLog new];

  // errodId – used for deduplication in case we sent the same crashreport twice.
  errorLog.errorId = [self errorIdForCrashReport:report];

  // set applicationpath and process info
  errorLog = [self addProcessInfoAndApplicationPathTo:errorLog fromCrashReport:report];

  // Find the crashed thread
  SNMPLCrashReportThreadInfo *crashedThread = [self findCrashedThreadInReport:report];

  // Error Thread Info.
  errorLog.errorThreadId = @(crashedThread.threadNumber);

  // errorLog.errorThreadName won't be used on iOS right now, will be relevant for handled exceptions.

  // All errors are fatal for now, until we add support for handled exceptions.
  errorLog.fatal = YES;

  // appLaunchTOffset - the difference between crashtime and initialization time, so the "age" of the crashreport before
  // it's forwarded to the channel.
  // We don't care about a negative difference (will happen if the user's time on the device changes to a time before
  // the crashTime and the time the error is processed).
  errorLog.appLaunchTOffset = [self calculateAppLaunchTOffsetFromReport:report];
  errorLog.toffset = [self calculateTOffsetFromReport:report];

  // CPU Type and Subtype
  errorLog.primaryArchitectureId = @(report.systemInfo.processorInfo.type);
  errorLog.architectureVariantId = @(report.systemInfo.processorInfo.subtype);

  // errorLog.architecture is an optional. The Android SDK will set it while for iOS, the file will be set
  // server-side using primaryArchitectureId and architectureVariantId.

  // TODO: Check this during testing/crashprobe
  // HockeyApp didn't use report.exceptionInfo for this field but exception.name in case of an unhandled exception or
  // the report.signalInfo.name
  // more so, for BITCrashDetails, we used the exceptionInfo.exceptionName for a field called exceptionName. FYI: Gwynne
  // has no idea. Andreas will be next ;)
  errorLog.osExceptionType = report.exceptionInfo.exceptionName ?: report.signalInfo.name;

  errorLog.osExceptionCode = report.signalInfo.code; // TODO check with Andreas/Gwynne

  errorLog.osExceptionAddress =
      [NSString stringWithFormat:@"0x%" PRIx64, report.signalInfo.address]; // TODO check with Andreas/Gwynne

  errorLog.exceptionReason =
      [self extractExceptionReasonFromReport:report ofCrashedThread:crashedThread is64bit:is64bit];

  errorLog.exceptionType = report.signalInfo.name;

  errorLog.threads = [self extractThreadsFromReport:report crashedThread:crashedThread is64bit:is64bit];
  errorLog.registers = [self extractRegistersFromCrashedThread:crashedThread is64bit:is64bit];

  // Gather all addresses for which we need to preserve the binary image.
  NSArray *addresses = [self addressesFromReport:report];
  errorLog.binaries = [self extractBinaryImagesFromReport:report addresses:addresses codeType:codeType is64bit:is64bit];

  return errorLog;
}

+ (SNMErrorReport *)errorReportFromCrashReport:(SNMPLCrashReport *)report {
  if (!report) {
    return nil;
  }

  SNMAppleErrorLog *errorLog = [self errorLogFromCrashReport:report];
  SNMErrorReport *errorReport = [self errorReportFromLog:errorLog];
  return errorReport;
}

+ (SNMErrorReport *)errorReportFromLog:(SNMAppleErrorLog *)errorLog {
  SNMErrorReport *errorReport = nil;

  NSString *errorId = errorLog.errorId;
  // There should always be an installId. Leaving the empty string out of paranoia
  // as [UUID UUID] – used in [MSSonoma installId] – might, in theory, return nil.
  NSString *reporterKey = [[MSSonoma installId] UUIDString] ?: @"";

  NSString *signal = errorLog.exceptionType; //TODO What should we put in there?!

  NSString *exceptionReason = errorLog.exceptionReason;
  NSString *exceptionName = errorLog.exceptionType;

  //errorlog.toffset represents the timestamp when the app crashed, appLaunchTOffset is the difference/offset between
  //the moment the app was launched and when the app crashed.

  NSDate *appStartTime =
      [NSDate dateWithTimeIntervalSince1970:([errorLog.toffset doubleValue] - [errorLog.appLaunchTOffset doubleValue])];
  NSDate *appErrorTime = [NSDate dateWithTimeIntervalSince1970:[errorLog.toffset doubleValue]];

  NSUInteger processId = [errorLog.processId unsignedIntegerValue];

  MSDevice *device = [MSDeviceTracker alloc].device;

  errorReport = [[SNMErrorReport alloc] initWithErrorId:errorId
                                            reporterKey:reporterKey
                                                 signal:signal
                                          exceptionName:exceptionName
                                        exceptionReason:exceptionReason
                                           appStartTime:appStartTime
                                           appErrorTime:appErrorTime
                                                 device:device
                                   appProcessIdentifier:processId];

  return errorReport;
}

#pragma mark - Private

#pragma mark - Parse SNMPLCrashReport

+ (NSString *)errorIdForCrashReport:(SNMPLCrashReport *)report {
  NSString *errorId = report.uuidRef ? (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, report.uuidRef))
      : [[NSUUID UUID] UUIDString];
  return errorId;
}

+ (SNMAppleErrorLog *)addProcessInfoAndApplicationPathTo:(SNMAppleErrorLog *)errorLog
                                         fromCrashReport:(SNMPLCrashReport *)crashReport {
  // Set the defaults first.
  errorLog.processId = @(0);
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

    // Parent Process Name.
    if (crashReport.processInfo.parentProcessName != nil) {
      errorLog.parentProcessName = crashReport.processInfo.parentProcessName;
    }
    // Parent Process ID.
    errorLog.parentProcessId = @(crashReport.processInfo.parentProcessID);
  }
  return errorLog;
}

+ (NSNumber *)calculateAppLaunchTOffsetFromReport:(SNMPLCrashReport *)report {
  NSDate *crashTime = report.systemInfo.timestamp;
  if (report.processInfo) {
    NSDate *startTime = report.processInfo.processStartTime;
    NSTimeInterval difference = [crashTime timeIntervalSinceDate:startTime];
    return @(difference);
  } else {
    // Use difference between now and crashtime as appLaunchTOffset as fallback.
    NSTimeInterval difference = [[NSDate date] timeIntervalSinceDate:crashTime];
    return @(difference);
  }
}

+ (NSNumber *)calculateTOffsetFromReport:(SNMPLCrashReport *)report {
  NSDate *crashTime = report.systemInfo.timestamp;
  NSTimeInterval difference = [crashTime timeIntervalSince1970];
  return @(difference);
}

+ (NSArray<SNMThread *> *)extractThreadsFromReport:(SNMPLCrashReport *)report crashedThread:(SNMPLCrashReportThreadInfo *)crashedThread is64bit:(BOOL)is64bit {
  NSMutableArray<SNMThread *> *formattedThreads = [NSMutableArray array];
  SNMException *lastException = nil;

  // If CrashReport contains Exception, add the threads that belong to the exception to the list of threads.
  if (report.exceptionInfo != nil && report.exceptionInfo.stackFrames != nil &&
      [report.exceptionInfo.stackFrames count] > 0) {
    SNMPLCrashReportExceptionInfo *exception = report.exceptionInfo;

    SNMThread *exceptionThread = [SNMThread new];
    exceptionThread.threadId = @(-1);

    // Gather frames from the thread's exception.
    for (SNMPLCrashReportStackFrameInfo *frameInfo in exception.stackFrames) {
      SNMStackFrame *frame = [SNMStackFrame new];
      frame.address = formatted_address_matching_architecture(frameInfo.instructionPointer, is64bit);
      [exceptionThread.frames addObject:frame];
    }

    lastException = [SNMException new];
    lastException.message = exception.exceptionReason;
    lastException.frames = exceptionThread.frames;
    lastException.type = report.exceptionInfo.exceptionName ?: report.signalInfo.name;

    // Don't add the thread to the array of threads (as in HockeyApp), the exception will be added to the crashed thread instead.
  }

  // Get all threads from the report (as opposed to the threads from the exception).
  for (SNMPLCrashReportThreadInfo *plCrashReporterThread in report.threads) {
    SNMThread *thread = [SNMThread new];
    thread.threadId = @(plCrashReporterThread.threadNumber);

    if ((lastException != nil) && (crashedThread != nil) && [thread.threadId isEqualToNumber:@(crashedThread.threadNumber)]) {
      thread.exception = lastException;
    }

    /* Write out the frames. In raw reports, Apple writes this out as a simple
     * list of PCs. In the minimally post-processed report, Apple writes this out as full frame entries. We
     * use the latter format. */
    for (SNMPLCrashReportStackFrameInfo *plCrashReporterFrameInfo in plCrashReporterThread.stackFrames) {
      SNMStackFrame *frame = [SNMStackFrame new];
      frame.address = formatted_address_matching_architecture(plCrashReporterFrameInfo.instructionPointer, is64bit);
      frame.code = [self formatStackFrame:plCrashReporterFrameInfo report:report];
      [thread.frames addObject:frame];
    }

    [formattedThreads addObject:thread];
  }

  return formattedThreads;
}

/**
 * Format a stack frame for display in a thread backtrace.
 *
 * @param frameInfo The stack frame to format
 * @param frameIndex The frame's index
 * @param report The report from which this frame was acquired.
 * @param lp64 If YES, the report was generated by an LP64 system.
 *
 * @return Returns a formatted frame line.
 */
+ (NSString *)formatStackFrame:(SNMPLCrashReportStackFrameInfo *)frameInfo report:(SNMPLCrashReport *)report {
  /* Base image address containing instrumentation pointer, offset of the IP from that base
   * address, and the associated image name */
  uint64_t baseAddress = 0x0;
  uint64_t pcOffset = 0x0;
  NSString *symbolString = nil;

  SNMPLCrashReportBinaryImageInfo *imageInfo = [report imageForAddress:frameInfo.instructionPointer];
  if (imageInfo != nil) {
    baseAddress = imageInfo.imageBaseAddress;
    pcOffset = frameInfo.instructionPointer - imageInfo.imageBaseAddress;
  }

  /* If symbol info is available, the format used in Apple's reports is Sym + OffsetFromSym. Otherwise,
   * the format used is imageBaseAddress + offsetToIP */
  SNMBinaryImageType imageType =
      [self imageTypeForImagePath:imageInfo.imageName processPath:report.processInfo.processPath];
  if (frameInfo.symbolInfo != nil && imageType == SNMBinaryImageTypeOther) {
    NSString *symbolName = frameInfo.symbolInfo.symbolName;

    /* Apple strips the _ symbol prefix in their reports. Only OS X makes use of an
     * underscore symbol prefix by default. */
    if ([symbolName rangeOfString:@"_"].location == 0 && [symbolName length] > 1) {
      switch (report.systemInfo.operatingSystem) {
      case PLCrashReportOperatingSystemMacOSX:
      case PLCrashReportOperatingSystemiPhoneOS:
      case PLCrashReportOperatingSystemiPhoneSimulator:symbolName = [symbolName substringFromIndex:1];
        break;

      default:NSLog(@"Symbol prefix rules are unknown for this OS!");
        break;
      }
    }

    uint64_t symOffset = frameInfo.instructionPointer - frameInfo.symbolInfo.startAddress;
    symbolString = [NSString stringWithFormat:@"%@ + %" PRId64, symbolName, symOffset];
  } else {
    symbolString = [NSString stringWithFormat:@"0x%" PRIx64 " + %" PRId64, baseAddress, pcOffset];
  }

  /* Note that width specifiers are ignored for %@, but work for C strings.
   * UTF-8 is not correctly handled with %s (it depends on the system encoding), but
   * UTF-16 is supported via %S, so we use it here */
  return symbolString;
}

+ (NSDictionary<NSString *, NSString *> *)extractRegistersFromCrashedThread:(SNMPLCrashReportThreadInfo *)crashedThread
                                                                    is64bit:(BOOL)is64bit {
  NSMutableDictionary<NSString *, NSString *> *registers = [NSMutableDictionary new];

  for (SNMPLCrashReportRegisterInfo *registerInfo in crashedThread.registers) {
    NSString *regName = registerInfo.registerName;

    NSString *formattedRegName = [NSString stringWithFormat:@"%s", [regName UTF8String]];
    NSString *formattedRegValue = formatted_address_matching_architecture(registerInfo.registerValue, is64bit);

    [registers setObject:formattedRegValue forKey:formattedRegName];
  }

  return registers;
}

+ (NSString *)extractExceptionReasonFromReport:(SNMPLCrashReport *)report
                               ofCrashedThread:(SNMPLCrashReportThreadInfo *)crashedThread
                                       is64bit:(BOOL)is64bit {
  NSString *exceptionReason = nil;
  /* Uncaught Exception */
  if (report.hasExceptionInfo) {
    exceptionReason = [NSString stringWithString:report.exceptionInfo.exceptionReason];
  } else if (crashedThread != nil) {
    // Try to find the selector in case this was a crash in obj_msgSend.
    // We search this whether the crash happened in obj_msgSend or not since we don't have the symbol!

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
      exceptionReason = foundSelector;
    }
  }

  return exceptionReason;
}

+ (NSArray<SNMBinary *> *)extractBinaryImagesFromReport:(SNMPLCrashReport *)report
                                              addresses:(NSArray *)addresses
                                               codeType:(NSNumber *)codeType
                                                is64bit:(BOOL)is64bit {
  NSMutableArray<SNMBinary *> *binaryImages = [NSMutableArray array];
  /* Images. The iPhone crash report format sorts these in ascending order, by
   * the base address */
  for (SNMPLCrashReportBinaryImageInfo *imageInfo in
      [report.images sortedArrayUsingFunction:bit_binaryImageSort context:nil]) {
    SNMBinary *binary = [SNMBinary new];

    binary.binaryId = (imageInfo.hasImageUUID) ? imageInfo.imageUUID : unknownString;

    uint64_t startAddress = imageInfo.imageBaseAddress;
    binary.startAddress = formatted_address_matching_architecture(startAddress, is64bit);

    uint64_t endAddress = imageInfo.imageBaseAddress + (MAX((uint64_t) 1, imageInfo.imageSize) - 1);
    binary.endAddress = formatted_address_matching_architecture(endAddress, is64bit);

    BOOL binaryIsInAddresses = [self isBinaryWithStart:startAddress end:endAddress inAddresses:addresses];
    SNMBinaryImageType imageType =
        [self imageTypeForImagePath:imageInfo.imageName processPath:report.processInfo.processPath];

    if (binaryIsInAddresses || (imageType != SNMBinaryImageTypeOther)) {

      /* Remove username from the image path */
      NSString *imagePath = @"";
      if (imageInfo.imageName && [imageInfo.imageName length] > 0) {
#if TARGET_IPHONE_SIMULATOR
        imagePath = [imageInfo.imageName stringByAbbreviatingWithTildeInPath];
#else
        imagePath = imageInfo.imageName;
#endif
      }
#if TARGET_IPHONE_SIMULATOR
      imagePath = [self anonymizedPathFromPath:imagePath];
#endif

      binary.path = imagePath;

      NSString *imageName = [imageInfo.imageName lastPathComponent] ?: @"\?\?\?";
      binary.name = imageName;

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
+ (NSString *)anonymizedPathFromPath:(NSString *)path {

  NSString *anonymizedProcessPath = [NSString string];

  if (([path length] > 0) && [path hasPrefix:@"/Users/"]) {
    NSError *error = nil;
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:@"(/Users/[^/]+/)" options:0 error:&error];
    anonymizedProcessPath = [regex stringByReplacingMatchesInString:path
                                                            options:0
                                                              range:NSMakeRange(0, [path length])
                                                       withTemplate:@"/Users/USER/"];
    if (error) {
      SNMLogError([SNMCrashes getLoggerTag], @"String replacing failed - %@", error.localizedDescription);
    }
  } else if (([path length] > 0) && (![path containsString:@"Users"])) {
    return path;
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
                                        regAddress - (uint64_t) imageForRegAddress.imageBaseAddress);

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

  if (!imagePath || !processPath) {
    return imageType;
  }

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

#pragma mark - Helpers

+ (NSNumber *)extractCodeTypeFromReport:(const SNMPLCrashReport *)report {
  NSDictionary<NSNumber *, NSNumber *> *legacyTypes = @{
      @(PLCrashReportArchitectureARMv6): @(CPU_TYPE_ARM),
      @(PLCrashReportArchitectureARMv7): @(CPU_TYPE_ARM),
      @(PLCrashReportArchitectureX86_32): @(CPU_TYPE_X86),
      @(PLCrashReportArchitectureX86_64): @(CPU_TYPE_X86_64),
      @(PLCrashReportArchitecturePPC): @(CPU_TYPE_POWERPC),
  };
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  /* Attempt to derive the code type from the binary images */
  NSNumber *codeType = nil;
  for (SNMPLCrashReportBinaryImageInfo *image in report.images) {
    codeType = @(image.codeType.type) ?: @(report.systemInfo.processorInfo.type)
        ?: legacyTypes[@(report.systemInfo.architecture)];

    /* Stop immediately if code type was discovered */
    if (codeType != nil)
      break;
  }
#pragma GCC diagnostic pop
  return codeType;
}

+ (BOOL)isCodeType64bit:(NSNumber *)codeType {
  NSDictionary<NSNumber *, NSNumber *> *codeTypesAre64bit = @{
      @(CPU_TYPE_ARM): @NO,
      @(CPU_TYPE_ARM64): @YES,
      @(CPU_TYPE_X86): @NO,
      @(CPU_TYPE_X86_64): @YES,
      @(CPU_TYPE_POWERPC): @NO,
  };
  NSNumber *boolNumber = codeTypesAre64bit[codeType];
  return boolNumber.boolValue;
}

+ (SNMPLCrashReportThreadInfo *)findCrashedThreadInReport:(SNMPLCrashReport *)report {
  SNMPLCrashReportThreadInfo *crashedThread;
  for (SNMPLCrashReportThreadInfo *thread in report.threads) {
    if (thread.crashed) {
      crashedThread = thread;
      break;
    }
  }
  return crashedThread;
}

+ (NSArray *)addressesFromReport:(SNMPLCrashReport *)report {
  NSMutableArray *addresses = [NSMutableArray new];

  if (report.exceptionInfo != nil && report.exceptionInfo.stackFrames != nil &&
      [report.exceptionInfo.stackFrames count] > 0) {
    SNMPLCrashReportExceptionInfo *exception = report.exceptionInfo;

    for (SNMPLCrashReportStackFrameInfo *frameInfo in exception.stackFrames) {
      [addresses addObject:@(frameInfo.instructionPointer)];
    }
  }

  for (SNMPLCrashReportThreadInfo *plCrashReporterThread in report.threads) {
    for (SNMPLCrashReportStackFrameInfo *plCrashReporterFrameInfo in plCrashReporterThread.stackFrames) {
      [addresses addObject:@(plCrashReporterFrameInfo.instructionPointer)];
    }

    for (SNMPLCrashReportRegisterInfo *registerInfo in plCrashReporterThread.registers) {
      [addresses addObject:@(registerInfo.registerValue)];
    }
  }

  return addresses;
}

@end
