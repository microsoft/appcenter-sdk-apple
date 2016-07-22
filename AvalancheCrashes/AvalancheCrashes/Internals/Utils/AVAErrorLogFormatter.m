/*
 * Authors:
 *  Landon Fuller <landonf@plausiblelabs.com>
 *  Damian Morris <damian@moso.com.au>
 *  Andreas Linde <mail@andreaslinde.de>
 *
 * Copyright (c) 2008-2013 Plausible Labs Cooperative, Inc.
 * Copyright (c) 2010 MOSO Corporation, Pty Ltd.
 * Copyright (c) 2012-2014 HockeyApp, Bit Stadium GmbH.
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


static NSString * formatted_address_matching_architecture (uint64_t address, BOOL is64bit) {
  return [NSString stringWithFormat:@"0x%0*" PRIx64, 8 << !!is64bit, address];
}

@implementation AVAErrorLogFormatter

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

  AVAErrorLog *errorLog = [AVAErrorLog new];

  // Gather all addresses for which we need to preserve the binary image
  NSMutableArray *addresses = [NSMutableArray new];

  AVAPLCrashReportThreadInfo *crashedThread = nil;
  for (AVAPLCrashReportThreadInfo *thread in report.threads) {
    if (thread.crashed) {
      crashedThread = thread;
      break;
    }
  }
  
  errorLog.threads = [self extractThreadsFromReport:report is64bit:is64bit addresses:&addresses];
//  crashData.headers = [self extractCrashDataHeadersFromReport:report codeType:codeType is64bit:is64bit crashedThread:crashedThread];
//  crashData.binaries = [self extractBinaryImagesFromReport:report addresses:addresses codeType:codeType is64bit:is64bit];
  
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



@end
