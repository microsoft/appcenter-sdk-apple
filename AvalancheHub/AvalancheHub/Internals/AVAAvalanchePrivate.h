/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAvalanche.h"
#import "AVAAvalancheDelegate.h"
#import "AVADeviceTracker.h"
#import "AVAFeaturePrivate.h"
#import "AVALogManager.h"
#import "AVALoggerPrivate.h"
#import "AVASender.h"
#import "AVAStorage.h"
#import <Foundation/Foundation.h>

// Install Id key in persisted storage.
static NSString *const kAVAInstallIdKey = @"AVAInstallId";

@class AVAFeature;

@interface AVAAvalanche () <AVAAvalancheDelegate>

@property(nonatomic) id<AVALogManager> logManager;
@property(nonatomic) NSMutableArray<NSObject<AVAFeaturePrivate> *> *features;
@property(nonatomic, copy) NSString *appKey;
@property(nonatomic, readonly) NSUUID *installId;
@property(nonatomic) NSString *apiVersion;
@property BOOL featuresStarted;
@property BOOL isEnabled;
@property(nonatomic) AVADeviceTracker *deviceTracker;
@property (nonatomic) NSString* sessionId;

- (NSString *)appKey;
- (NSString *)apiVersion;

@end
