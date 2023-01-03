//
//  MSACDistributeArchiverUtil.m
//  AppCenterDistribute iOS Framework
//
//  Copyright © 2023 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSACDistributeArchiverUtil.h"
#import "MSACUtility.h"
#import "MSACDevice.h"
#import "MSACDistributionStartSessionLog.h"
#import "MSACReleaseDetails.h"
#import "MSACErrorDetails.h"

@implementation MSACDistributeArchiverUtil

+ (void) addAllowedDistributeModuleClasses
{
    NSArray *allowedClassesArray = @[[MSACReleaseDetails class], [MSACErrorDetails class], [MSACDistributionStartSessionLog class], [MSACDevice class], [NSDate class], [NSDictionary class], [NSArray class], [NSNull class], [NSMutableData class], [NSString class], [NSNumber class], [NSMutableArray class]];
              
    [MSACUtility addAllowedClasses: allowedClassesArray];
}

@end
