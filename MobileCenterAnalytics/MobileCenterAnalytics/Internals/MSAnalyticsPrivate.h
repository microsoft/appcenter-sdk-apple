/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAnalytics.h"
#import "MSFeatureInternal.h"
#import "MSSessionTracker.h"
#import "MSSessionTrackerDelegate.h"

@interface MSAnalytics () <MSSessionTrackerDelegate>

/**
 *  Session tracking component
 */
@property(nonatomic) MSSessionTracker *sessionTracker;

@property(nonatomic) BOOL autoPageTrackingEnabled;

@end
