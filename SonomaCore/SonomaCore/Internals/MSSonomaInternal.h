/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSFeatureInternal.h"
#import "MSLogManager.h"
#import "MSSonoma.h"
#import "MobileCenter+Internal.h"
#import <Foundation/Foundation.h>

// Persisted storage keys.
static NSString *const kSNMInstallIdKey = @"SNMInstallId";
static NSString *const kSNMCoreIsEnabledKey = @"kSNMCoreIsEnabledKey";

@class SNMFeature;

@interface MSSonoma ()

@property(nonatomic) id <MSLogManager> logManager;
@property(nonatomic) NSMutableArray<NSObject <MSFeatureInternal> *> *features;
@property(nonatomic, copy) NSString *appSecret;
@property(nonatomic) NSString *serverUrl;
@property(nonatomic, readonly) NSUUID *installId;
@property(nonatomic) NSString *apiVersion;
@property BOOL sdkStarted;
@property(atomic) BOOL enabledStateUpdating;

/**
 * Returns the singleton instance of SonomaCore.
 */
+ (instancetype)sharedInstance;
- (NSString *)serverUrl;
- (NSString *)appSecret;
- (NSString *)apiVersion;

/**
 *  Enable or disable the SDK as a whole. In addition to the core resources, it will also enable or disable all
 * registered features.
 *
 *  @param isEnabled YES to enable, NO to disable.
 *  @see isEnabled
 */
- (void)setEnabled:(BOOL)isEnabled;

/**
 *  Check whether the SDK is enabled or not as a whole.
 *
 *  @return YES if enabled, NO otherwise.
 *  @see setEnabled:
 */
- (BOOL)isEnabled;

/**
 * Get the logger tag for core module.
 *
 * @return A name of logger tag for core module.
 */
+ (NSString *)getLoggerTag;

@end
