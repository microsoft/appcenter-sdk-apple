// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import "MSACAnalyticsArchiverUtil.h"
#import "MSACBooleanTypedProperty.h"
#import "MSACDateTimeTypedProperty.h"
#import "MSACDeviceHistoryInfo.h"
#import "MSACDoubleTypedProperty.h"
#import "MSACEventLog.h"
#import "MSACEventProperties.h"
#import "MSACEventPropertiesInternal.h"
#import "MSACLongTypedProperty.h"
#import "MSACPageLog.h"
#import "MSACSessionContext.h"
#import "MSACStartSessionLog.h"
#import "MSACStringTypedProperty.h"
#import "MSACTypedProperty.h"
#import "MSACUserIdContext.h"
#import "MSACUtility+StringFormatting.h"
#import "MSACUtility.h"
#import <Foundation/Foundation.h>

@implementation MSACAnalyticsArchiverUtil

+ (void)addAllowedAnalyitcsModuleClasses {
  NSArray *allowedClassesArray = @[
    [MSACSessionHistoryInfo class],
    [NSDate class],
    [MSACDevice class],
    [MSACAbstractLog class],
    [MSACEventLog class],
    [MSACPageLog class],
    [MSACEventProperties class],
    [MSACLogWithNameAndProperties class],
    [MSACBooleanTypedProperty class],
    [MSACDateTimeTypedProperty class],
    [MSACDoubleTypedProperty class],
    [MSACLongTypedProperty class],
    [MSACStringTypedProperty class],
    [MSACTypedProperty class],
    [MSACStartSessionLog class],
    [NSDictionary class],
    [MSACStartSessionLog class],
    [NSString class],
    [NSNumber class],
    [NSMutableArray class]
  ];
  [MSACUtility addAllowedClasses:allowedClassesArray];
}

@end
