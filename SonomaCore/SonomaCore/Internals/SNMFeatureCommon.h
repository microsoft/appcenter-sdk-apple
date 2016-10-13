/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMLogManager.h"
#import <Foundation/Foundation.h>

/**
 *  Protocol declaring features common logic.
 */
@protocol SNMFeatureCommon <NSObject>

/**
 *  Log manager.
 */
@property(nonatomic) id<SNMLogManager> logManager;

/**
 *  Triggered while log manager is ready to be used.
 *
 *  @param logManager log manager.
 */
- (void)onLogManagerReady:(id<SNMLogManager>)logManager;

@optional

/**
 *  Feature unique key for storage purpose.
 *  @discussion: IMPORTANT, This string is used to point to the right storage value for this feature.
 *  Changing this string results in data lost if previous data is not migrated.
 */
@property(nonatomic, readonly) NSString *storageKey;

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
 * Check if the SDK has been properly initialized and the feature can be used. Logs an error in case it wasn't.
 * @return a BOOL to indicate proper initialization of the SDK.
 */
- (BOOL)canBeUsed;

/**
 * Start this feature. Also sets the flag that indicates that a feature has been started.
 */
- (void)startFeature;

@end
