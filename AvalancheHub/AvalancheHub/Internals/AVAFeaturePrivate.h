/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAFeature.h"
#import "AVAAvalancheDelegate.h"

@interface AVAFeature ()

@property (nonatomic, weak) id<AVAAvalancheDelegate> delegate;

+ (id)sharedInstance;
- (void)startFeature;

@end
