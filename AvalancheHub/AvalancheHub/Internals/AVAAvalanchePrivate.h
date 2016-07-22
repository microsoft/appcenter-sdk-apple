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
#import "AVASessionTracker.h"
#import "AVASessionTrackerDelegate.h"
#import "AVAStorage.h"
#import <Foundation/Foundation.h>

@class AVAFeature;

@interface AVAAvalanche () <AVAAvalancheDelegate, AVASessionTrackerDelegate>

@property(nonatomic) id<AVALogManager> logManager;
@property(nonatomic) NSMutableArray<NSObject<AVAFeaturePrivate> *> *features;
@property(nonatomic, copy) NSString *appKey;
@property(nonatomic) NSString *installId;
@property(nonatomic) NSString *apiVersion;
@property BOOL featuresStarted;
@property(nonatomic) AVASessionTracker *sessionTracker;
@property(nonatomic) AVADeviceTracker *deviceTracker;

- (NSString *)appKey;
- (NSUUID *)installId;
- (NSString *)apiVersion;
- (void)setInstallId;

@end
