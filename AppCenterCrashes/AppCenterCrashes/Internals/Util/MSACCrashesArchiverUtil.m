// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACCrashesArchiverUtil.h"
#import "MSACAppleErrorLog.h"
#import "MSACBinary.h"
#import "MSACDevice.h"
#import "MSACErrorAttachmentLog+Utility.h"
#import "MSACErrorAttachmentLog.h"
#import "MSACErrorAttachmentLogInternal.h"
#import "MSACErrorReport.h"
#import "MSACHandledErrorLog.h"
#import "MSACStackFrame.h"
#import "MSACThread.h"
#import "MSACUtility+File.h"
#import "MSACUtility.h"
#import "MSACWrapperException.h"
#import "MSACWrapperExceptionModel.h"
#import <Foundation/Foundation.h>

@implementation MSACCrashesArchiverUtil

+ (void)addAllowedCrashesModuleClasses {
  NSArray *allowedClassesArray = @[
    [MSACAppleErrorLog class],
    [NSDate class],
    [MSACDevice class],
    [MSACThread class],
    [MSACWrapperException class],
    [MSACAbstractErrorLog class],
    [MSACHandledErrorLog class],
    [MSACWrapperExceptionModel class],
    [MSACStackFrame class],
    [MSACBinary class],
    [MSACErrorAttachmentLog class],
    [MSACErrorReport class],
    [MSACWrapperSdk class],
    [NSUUID class],
    [NSDictionary class],
    [NSArray class],
    [NSNull class],
    [MSACLogWithProperties class],
    [MSACCommonSchemaLog class],
    [NSMutableData class],
    [MSACExceptionModel class],
    [NSString class],
    [NSNumber class],
    [NSMutableArray class]
  ];
  [MSACUtility addAllowedClasses:allowedClassesArray];
}

@end
