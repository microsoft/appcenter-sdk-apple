/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASonomaDelegate.h"
#import "AVAFeature.h"
#import "AVAFeatureCommon.h"
#import "AVALogManager.h"

/**
 *  Protocol declaring all the logic of a feature. This is what concrete features needs to conform to.
 */
@protocol AVAFeatureInternal <AVAFeature, AVAFeatureCommon>

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
