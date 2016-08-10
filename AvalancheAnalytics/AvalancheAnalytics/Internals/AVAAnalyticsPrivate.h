/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAnalytics.h"
#import "AVASessionTracker.h"
#import "Internals/AVAFeaturePrivate.h"
#import "AVASessionTrackerDelegate.h"

@interface AVAAnalytics () <AVAFeaturePrivate, AVASessionTrackerDelegate>

/**
 *  Session tracking component
 */
@property(nonatomic) AVASessionTracker *sessionTracker;

@property(nonatomic) BOOL autoPageTrackingEnabled;

+ (id)sharedInstance;

@end
