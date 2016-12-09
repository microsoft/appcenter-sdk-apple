/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAnalytics.h"
#import "MSServiceInternal.h"
#import "MSSessionTracker.h"
#import "MSSessionTrackerDelegate.h"
#import "MSAnalyticsDelegate.h"

@interface MSAnalytics () <MSSessionTrackerDelegate>

/**
 *  Session tracking component
 */
@property(nonatomic) MSSessionTracker *sessionTracker;

@property(nonatomic) BOOL autoPageTrackingEnabled;

@property(nonatomic) id<MSAnalyticsDelegate> delegate;

@end
