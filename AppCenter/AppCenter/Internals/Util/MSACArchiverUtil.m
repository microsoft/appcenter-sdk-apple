// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACArchiverUtil.h"
#import "MSACAppExtension.h"
#import "MSACBooleanTypedProperty.h"
#import "MSACCSData.h"
#import "MSACCSExtensions.h"
#import "MSACCommonSchemaLog.h"
#import "MSACDateTimeTypedProperty.h"
#import "MSACDeviceExtension.h"
#import "MSACDeviceHistoryInfo.h"
#import "MSACDoubleTypedProperty.h"
#import "MSACLocExtension.h"
#import "MSACLogWithProperties.h"
#import "MSACLongTypedProperty.h"
#import "MSACMetadataExtension.h"
#import "MSACNetExtension.h"
#import "MSACOSExtension.h"
#import "MSACProtocolExtension.h"
#import "MSACSDKExtension.h"
#import "MSACSessionHistoryInfo.h"
#import "MSACStartServiceLog.h"
#import "MSACStringTypedProperty.h"
#import "MSACTypedProperty.h"
#import "MSACUserExtension.h"
#import "MSACUserIdContext.h"
#import "MSACUserIdHistoryInfo.h"
#import "MSACUtility.h"
#import "MSACWrapperSdk.h"
#import <Foundation/Foundation.h>

@implementation MSACArchiverUtil

+ (void)addAllowedAppCenterModuleClasses {

  NSArray *allowedClasses = @[
    [MSACAbstractLog class],
    [NSDate class],
    [MSACDevice class],
    [MSACDeviceHistoryInfo class],
    [MSACSessionHistoryInfo class],
    [MSACUserIdHistoryInfo class],
    [MSACAppExtension class],
    [MSACCSExtensions class],
    [MSACCommonSchemaLog class],
    [MSACCSData class],
    [MSACDeviceExtension class],
    [MSACLocExtension class],
    [MSACMetadataExtension class],
    [MSACNetExtension class],
    [MSACOSExtension class],
    [MSACProtocolExtension class],
    [MSACSDKExtension class],
    [MSACUserExtension class],
    [MSACStartServiceLog class],
    [MSACBooleanTypedProperty class],
    [MSACDateTimeTypedProperty class],
    [MSACDoubleTypedProperty class],
    [MSACLongTypedProperty class],
    [MSACStringTypedProperty class],
    [MSACTypedProperty class],
    [MSACHistoryInfo class],
    [MSACLogWithProperties class],
    [MSACWrapperSdk class],
    [NSUUID class],
    [NSDictionary class],
    [NSArray class],
    [NSNull class],
    [NSString class],
    [NSNumber class],
    [NSMutableArray class]
  ];

  [MSACUtility addAllowedClasses:allowedClasses];
}

@end
