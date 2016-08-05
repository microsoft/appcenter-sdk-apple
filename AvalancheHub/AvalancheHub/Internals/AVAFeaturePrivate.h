/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAvalancheDelegate.h"
#import "AVAFeature.h"

@protocol AVAFeaturePrivate <NSObject>

@property(nonatomic, weak) id<AVAAvalancheDelegate> delegate;
@property(setter=setEnabled:) BOOL isEnabled;

+ (id)sharedInstance;
- (void)startFeature;

@end
