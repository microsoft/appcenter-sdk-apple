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
@property (nonatomic, copy) NSString *identifier;
@property BOOL featuresStarted;

@end
