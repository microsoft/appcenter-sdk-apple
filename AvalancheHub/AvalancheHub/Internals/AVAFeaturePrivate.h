/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAFeature.h"
#import "AVAAvalancheDelegate.h"

@protocol AVAFeaturePrivate <NSObject>

@property (nonatomic, weak) id<AVAAvalancheDelegate> delegate;
@property (setter=setEnabled:) BOOL isEnabled;

+ (id)sharedInstance;
- (void)startFeature;

@end
