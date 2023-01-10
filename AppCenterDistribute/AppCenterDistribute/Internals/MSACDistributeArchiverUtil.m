// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACDistributeArchiverUtil.h"
#import "MSACDevice.h"
#import "MSACDistributionStartSessionLog.h"
#import "MSACErrorDetails.h"
#import "MSACReleaseDetails.h"
#import "MSACUtility.h"
#import <Foundation/Foundation.h>

@implementation MSACDistributeArchiverUtil

+ (void)addAllowedDistributeModuleClasses {
  NSArray *allowedClassesArray = @[
    [MSACReleaseDetails class], [MSACErrorDetails class], [MSACDistributionStartSessionLog class], [MSACDevice class], [NSDate class],
    [NSDictionary class], [NSArray class], [NSNull class], [NSMutableData class], [NSString class], [NSNumber class], [NSMutableArray class]
  ];

  [MSACUtility addAllowedClasses:allowedClassesArray];
}

@end
