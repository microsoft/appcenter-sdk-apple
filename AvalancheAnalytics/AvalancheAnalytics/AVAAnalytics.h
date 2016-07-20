/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "AVAFeature.h"

@interface AVAAnalytics : NSObject <AVAFeature>

/**
 *  Track an event
 *
 *  @param eventName  event name
 *  @param properties dictionary of properties
 */
+ (void)trackEvent:(NSString*)eventName withProperties:(NSDictionary *)properties;

/**
 *  Track a page
 *
 *  @param eventName  page name
 *  @param properties dictionary of properties
 */
+ (void)trackPage:(NSString*)pageName withProperties:(NSDictionary *)properties;

/**
 *  Set the page auto-tracking property
 *
 *  @param isEnabled is page tracking enabled or disabled
 */

+ (void)setAutoPageTrackingEnabled:(BOOL)isEnabled;

/**
 *  Indicate if auto page tracking is enabled or not
 *
 *  @return YES is page tracking is enabled and NO if disabled
 */
+ (BOOL)isAutoPageTrackingEnabled;

@end
