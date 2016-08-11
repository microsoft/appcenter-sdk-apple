/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAvalancheDelegate.h"
#import "AVAFeature.h"
#import "AVALogManager.h"

@protocol AVAFeaturePrivate <NSObject>

@property(nonatomic, weak) id<AVAAvalancheDelegate> delegate;
@property(setter=setEnabled:) BOOL isEnabled;
@property (nonatomic) id<AVALogManager> logManger;

+ (id)sharedInstance;
- (void)startFeature;
- (void)onLogManagerReady:(id<AVALogManager>)logManger;

@end
