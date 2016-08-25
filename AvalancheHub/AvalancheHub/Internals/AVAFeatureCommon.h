/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAvalancheDelegate.h"
#import "AVALogManager.h"
#import <Foundation/Foundation.h>

/**
 *  Protocol declaring features common logic.
 */
@protocol AVAFeatureCommon <NSObject>

/**
 *  Avalanche delegate.
 */
@property(nonatomic, weak) id<AVAAvalancheDelegate> delegate;

/**
 *  Log manager.
 */
@property(nonatomic) id<AVALogManager> logManger;

/**
 *  Enable/Disable this feature.
 *
 *  @param isEnabled is this feature enabled or not.
 */
- (void)setEnabled:(BOOL)isEnabled;

/**
 *  Check whether this feature is enabled or not.
 */
- (BOOL)isEnabled;

/**
 *  Triggered while log manager is ready to be used.
 *
 *  @param logManger log manager.
 */
- (void)onLogManagerReady:(id<AVALogManager>)logManger;

@optional

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

/**
 * Log an SDK not initialized error message for the feature
 * @param the featurename
 */
- (void)logSDKNotInitializedError:(NSString *)featureName;

/**
 * Check if the SDK has been properly initialized
 * @return a BOOL to indicate proper initializatopn of the SDK.
 */
- (BOOL)sdkInitialized;

@end