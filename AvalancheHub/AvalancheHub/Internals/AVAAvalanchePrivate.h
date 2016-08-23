/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAvalanche.h"
#import "AVAAvalancheDelegate.h"
#import "AVAFeaturePrivate.h"
#import "AVALogManager.h"
#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

// Install Id key in persisted storage.
static NSString *const kAVAInstallIdKey = @"AVAInstallId";

@class AVAFeature;

@interface AVAAvalanche () <AVAAvalancheDelegate>

@property(nonatomic) id<AVALogManager> logManager;
@property(nonatomic) NSMutableArray<NSObject<AVAFeaturePrivate> *> *features;
@property(nonatomic, copy) NSString *appSecret;
@property(nonatomic, readonly) NSUUID *installId;
@property(nonatomic) NSString *apiVersion;
@property BOOL featuresStarted;
@property BOOL isEnabled;

- (NSString *)appSecret;
- (NSString *)apiVersion;

@end
