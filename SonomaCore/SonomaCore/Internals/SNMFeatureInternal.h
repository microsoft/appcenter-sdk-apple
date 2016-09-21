/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMSonomaDelegate.h"
#import "SNMFeature.h"
#import "SNMFeatureCommon.h"
#import "SNMLogManager.h"

/**
 *  Protocol declaring all the logic of a feature. This is what concrete features needs to conform to.
 */
@protocol SNMFeatureInternal <SNMFeature, SNMFeatureCommon>

/**
 *  The channel priority for this feature.
 */
@property(nonatomic, readonly) SNMPriority priority;

/**
 *  Get the unique instance.
 *
 *  @return unique instance.
 */
+ (instancetype)sharedInstance;

/**
 *  Feature unique name.
 *
 *  @return feature unique name.
 */
- (NSString *)featureName;

@end
