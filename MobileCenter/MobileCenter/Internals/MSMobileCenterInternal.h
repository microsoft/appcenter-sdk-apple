/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MobileCenter+Internal.h"
#import "MSLogManager.h"
#import "MSMobileCenter.h"
#import "MSServiceInternal.h"

@import Foundation;

// Persisted storage keys.
static NSString *const kMSInstallIdKey = @"MSInstallId";
static NSString *const kMSMobileCenterIsEnabledKey = @"MSMobileCenterIsEnabled";

@class MSService;

@interface MSMobileCenter ()

@property(nonatomic) id<MSLogManager> logManager;
@property(nonatomic) NSMutableArray<NSObject<MSServiceInternal> *> *services;
@property(nonatomic, copy) NSString *appSecret;
@property(nonatomic, copy) NSString *serverUrl;
@property(nonatomic, readonly) NSUUID *installId;
@property(nonatomic, copy) NSString *apiVersion;
@property BOOL sdkConfigured;
@property(atomic) BOOL enabledStateUpdating;

/**
 * Returns the singleton instance of Mobile Center.
 */
+ (instancetype)sharedInstance;
- (NSString *)serverUrl;
- (NSString *)appSecret;
- (NSString *)apiVersion;

/**
 * Enable or disable the SDK as a whole. In addition to MobileCenter resources, it will also enable or
 * disable all registered services.
 *
 * @param isEnabled YES to enable, NO to disable.
 * @see isEnabled
 */
- (void)setEnabled:(BOOL)isEnabled;

/**
 * Check whether the SDK is enabled or not as a whole.
 *
 * @return YES if enabled, NO otherwise.
 * @see setEnabled:
 */
- (BOOL)isEnabled;

/**
 * Get the log tag for the MobileCenter service.
 *
 * @return A name of logger tag for the MobileCenter service.
 */
+ (NSString *)logTag;

@end
