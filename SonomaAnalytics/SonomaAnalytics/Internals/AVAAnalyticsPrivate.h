/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAnalytics.h"
#import "AVAFeatureInternal.h"
#import "AVASessionTracker.h"
#import "AVASessionTrackerDelegate.h"

@interface AVAAnalytics () <AVAFeatureInternal, AVASessionTrackerDelegate>

/**
 *  Session tracking component
 */
@property(nonatomic) AVASessionTracker *sessionTracker;

@property(nonatomic) BOOL autoPageTrackingEnabled;

@end
