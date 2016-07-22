/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAnalytics.h"
#import "Internals/AVAFeaturePrivate.h"

@interface AVAAnalytics() <AVAFeaturePrivate>

@property (nonatomic) BOOL autoPageTrackingEnabled;

+ (id)sharedInstance;

@end
