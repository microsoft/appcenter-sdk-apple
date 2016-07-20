/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AVAAvalanche.h"
#import "AVALoggerPrivate.h"
#import "AVAAvalancheDelegate.h"
#import "AVALogManager.h"
#import "AVASessionTrackerDelegate.h"
#import "AVASender.h"
#import "AVAStorage.h"
#import "AVAFeaturePrivate.h"
#import "AVASessionTracker.h"

@class AVAFeature;

@interface AVAAvalanche () <AVAAvalancheDelegate, AVASessionTrackerDelegate>

@property (nonatomic) id<AVALogManager> logManager;
@property (nonatomic) NSMutableArray<NSObject<AVAFeaturePrivate> *> *features;
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic) NSString *installId;
@property (nonatomic) NSString *apiVersion;
@property BOOL featuresStarted;
@property BOOL isEnabled;
@property (nonatomic) AVASessionTracker *sessionTracker;

- (NSString*)appKey;
- (NSUUID*)installId;
- (NSString*)apiVersion;
- (void)setInstallId;

@end
