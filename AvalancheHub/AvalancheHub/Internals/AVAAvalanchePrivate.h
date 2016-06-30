/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AVAAvalanche.h"
#import "AVALoggerPrivate.h"
#import "AVAAvalancheDelegate.h"

@class AVAFeature;

@interface AVAAvalanche () <AVAAvalancheDelegate>

@property (nonatomic, strong) NSMutableArray<AVAFeature *> *features;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, retain) NSString *uuid;
@property BOOL featuresStarted;

- (NSString*)getAppId;
- (NSString*)getUUID;
- (NSString*)getApiVersion;

@end
