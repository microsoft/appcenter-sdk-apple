/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAnalytics.h"
#import "MSServiceInternal.h"
#import "MSAnalyticsDelegate.h"
#import "MSChannelDelegate.h"

@interface MSAnalytics () <MSServiceInternal, MSChannelDelegate>

// Temporarily hiding tracking page feature.
/**
 * Track a page.
 *
 * @param pageName  page name.
 */
+ (void)trackPage:(NSString *)pageName;

/**
 * Track a page.
 *
 * @param pageName  page name.
 * @param properties dictionary of properties.
 */
+ (void)trackPage:(NSString *)pageName withProperties:(NSDictionary *)properties;

/**
 * Set the page auto-tracking property.
 *
 * @param isEnabled is page tracking enabled or disabled.
 */

+ (void)setAutoPageTrackingEnabled:(BOOL)isEnabled;

/**
 * Indicate if auto page tracking is enabled or not.
 *
 * @return YES if page tracking is enabled and NO if disabled.
 */
+ (BOOL)isAutoPageTrackingEnabled;

/**
 * Validate keys and values of properties.
 *
 * @return YES if properties have valid keys and values, NO otherwise.
 */
- (BOOL)validateProperties:(NSDictionary<NSString *, NSString *> *)properties;

+ (void)setDelegate:(_Nullable id <MSAnalyticsDelegate>)delegate;

@end
