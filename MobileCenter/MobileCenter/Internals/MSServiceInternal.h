/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSService.h"
#import "MSServiceCommon.h"
#import "MSLogManager.h"

/**
 *  Protocol declaring all the logic of a service. This is what concrete services needs to conform to.
 */
@protocol MSServiceInternal <MSService, MSServiceCommon>

/**
 * Service unique key for storage purpose.
 * @discussion: IMPORTANT, This string is used to point to the right storage value for this service.
 * Changing this string results in data loss if previous data is not migrated.
 */
@property(nonatomic, copy, readonly) NSString *storageKey;

/**
 * The channel priority for this service.
 */
@property(nonatomic, readonly) MSPriority priority;

/**
 * Get the unique instance.
 *
 * @return unique instance.
 */
+ (instancetype)sharedInstance;

/**
 * Get the log tag for this service.
 *
 * @return A name of logger tag for this service.
 */
+ (NSString *)logTag;

@end
