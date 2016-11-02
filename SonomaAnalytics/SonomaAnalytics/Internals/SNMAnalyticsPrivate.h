/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMAnalytics.h"
#import "MSFeatureInternal.h"
#import "SNMSessionTracker.h"
#import "SNMSessionTrackerDelegate.h"

@interface SNMAnalytics () <SNMSessionTrackerDelegate>

/**
 *  Session tracking component
 */
@property(nonatomic) SNMSessionTracker *sessionTracker;

@property(nonatomic) BOOL autoPageTrackingEnabled;

@end
