/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAvalanche.h"
#import "AVAAvalancheDelegate.h"
#import "AVAFeatureInternal.h"
#import "AVALogManager.h"
#import "SonomaCore+Internal.h"
#import <Foundation/Foundation.h>

// Install Id key in persisted storage.
static NSString *const kAVAInstallIdKey = @"AVAInstallId";

@class AVAFeature;

@interface AVAAvalanche () <AVAAvalancheDelegate>

@property(nonatomic) id<AVALogManager> logManager;
@property(nonatomic) NSMutableArray<NSObject<AVAFeatureInternal> *> *features;
@property(nonatomic, copy) NSString *appSecret;
@property(nonatomic, readonly) NSUUID *installId;
@property(nonatomic) NSString *apiVersion;
@property BOOL sdkStarted;

/**
 * Returns the singleton instance of SonomaCore.
 */
+ (instancetype)sharedInstance;
- (NSString *)appSecret;
- (NSString *)apiVersion;

/**
 *  Enable or disable the SDK as a whole. In addition to the core resources, it will also enable or disable all
 * registered features.
 *
 *  @param isEnabled true to enable, false to disable.
 *  @see isEnabled
 */
- (void)setEnabled:(BOOL)isEnabled;

/**
 *  Check whether the SDK is enabled or not as a whole.
 *
 *  @return true if enabled, false otherwise.
 *  @see setEnabled:
 */
- (BOOL)isEnabled;

@end
