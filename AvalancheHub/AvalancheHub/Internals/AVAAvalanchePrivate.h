/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AVAAvalanche.h"
#import "AVALoggerPrivate.h"
#import "AVAAvalancheDelegate.h"
#import "AVAChannel.h"
#import "AVASender.h"
#import "AVAStorage.h"

@class AVAFeature;

@interface AVAAvalanche () <AVAAvalancheDelegate>

@property (nonatomic, strong) id<AVAChannel> channel;
@property (nonatomic, strong) NSMutableArray<AVAFeature *> *features;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSString *apiVersion;
@property BOOL featuresStarted;

- (NSString*)appId;
- (NSString*)UUID;
- (NSString*)apiVersion;

@end
