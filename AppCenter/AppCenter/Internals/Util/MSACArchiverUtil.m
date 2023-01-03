// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import "MSACArchiverUtil.h"
#import "MSACUtility.h"
#import "MSACDeviceHistoryInfo.h"
#import "MSACUserIdContext.h"
#import "MSACUserIdHistoryInfo.h"
#import "MSACSessionHistoryInfo.h"
#import "MSACCommonSchemaLog.h"
#import "MSACCSData.h"
#import "MSACDeviceExtension.h"
#import "MSACLocExtension.h"
#import "MSACCSExtensions.h"
#import "MSACMetadataExtension.h"
#import "MSACNetExtension.h"
#import "MSACOSExtension.h"
#import "MSACSDKExtension.h"
#import "MSACAppExtension.h"
#import "MSACProtocolExtension.h"
#import "MSACUserExtension.h"
#import "MSACStartServiceLog.h"
#import "MSACBooleanTypedProperty.h"
#import "MSACDoubleTypedProperty.h"
#import "MSACDateTimeTypedProperty.h"
#import "MSACStringTypedProperty.h"
#import "MSACLongTypedProperty.h"
#import "MSACTypedProperty.h"
#import "MSACWrapperSdk.h"
#import "MSACLogWithProperties.h"


@implementation MSACArchiverUtil

+ (void) addAllowedAppCenterModuleClasses {
    
    NSArray *allowedClasses = @[[MSACAbstractLog class], [NSDate class], [MSACDevice class], [MSACDeviceHistoryInfo class], [MSACSessionHistoryInfo class], [MSACUserIdHistoryInfo class], [MSACAppExtension class], [MSACCSExtensions class], [MSACCommonSchemaLog class], [MSACCSData class], [MSACDeviceExtension class], [MSACLocExtension class], [MSACMetadataExtension class], [MSACNetExtension class], [MSACOSExtension class], [MSACProtocolExtension class], [MSACSDKExtension class], [MSACUserExtension class], [MSACStartServiceLog class], [MSACBooleanTypedProperty class], [MSACDateTimeTypedProperty class], [MSACDoubleTypedProperty class], [MSACLongTypedProperty class], [MSACStringTypedProperty class], [MSACTypedProperty class], [MSACHistoryInfo class], [MSACLogWithProperties class], [MSACWrapperSdk class], [NSUUID class], [NSDictionary class], [NSArray class], [NSNull class], [NSString class], [NSNumber class],  [NSMutableArray class]];
        
    [MSACUtility addAllowedClasses: allowedClasses];
}

@end
