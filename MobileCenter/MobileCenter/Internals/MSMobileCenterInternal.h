/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSFeatureInternal.h"
#import "MSLogManager.h"
#import "MSMobileCenter.h"
#import "MobileCenter+Internal.h"
#import <Foundation/Foundation.h>

// Persisted storage keys.
static NSString *const kMSInstallIdKey = @"kMSInstallIdKey";
static NSString *const kMSMobileCenterIsEnabledKey = @"kMSMobileCenterIsEnabledKey";

@class MSFeature;

@interface MSMobileCenter ()

@property(nonatomic) id <MSLogManager> logManager;
@property(nonatomic) NSMutableArray<NSObject <MSFeatureInternal> *> *features;
@property(nonatomic, copy) NSString *appSecret;
@property(nonatomic) NSString *serverUrl;
@property(nonatomic, readonly) NSUUID *installId;
@property(nonatomic) NSString *apiVersion;
@property BOOL sdkStarted;
@property(atomic) BOOL enabledStateUpdating;

/**
 * Returns the singleton instance of Mobile Center.
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
