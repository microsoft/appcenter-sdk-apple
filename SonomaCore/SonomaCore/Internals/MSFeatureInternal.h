/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSFeature.h"
#import "MSFeatureCommon.h"
#import "MSLogManager.h"

/**
 *  Protocol declaring all the logic of a feature. This is what concrete features needs to conform to.
 */
@protocol MSFeatureInternal <MSFeature, MSFeatureCommon>

/**
 * Feature unique key for storage purpose.
 * @discussion: IMPORTANT, This string is used to point to the right storage value for this feature.
 * Changing this string results in data lost if previous data is not migrated.
 */
@property(nonatomic, readonly) NSString *storageKey;

/**
 * The channel priority for this feature.
 */
@property(nonatomic, readonly) MSPriority priority;

/**
 * Get the unique instance.
 *
 * @return unique instance.
 */
+ (instancetype)sharedInstance;

/**
 * Get the logger tag for this feature.
 *
 * @return A name of logger tag for this feature.
 */
+ (NSString *)getLoggerTag;

@end
