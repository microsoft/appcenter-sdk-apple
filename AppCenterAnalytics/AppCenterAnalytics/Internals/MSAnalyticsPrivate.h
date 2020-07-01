// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAnalytics.h"
#import "MSAnalyticsDelegate.h"
#import "MSAnalyticsTransmissionTarget.h"
#import "MSServiceInternal.h"
#import "MSSessionTracker.h"
#import "MSSessionTrackerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

// The Id suffix for critical events.
static NSString *const kMSCriticalChannelSuffix = @"critical";

@interface MSAnalytics () <MSSessionTrackerDelegate>

/**
 * Session tracking component.
 */
@property(nonatomic) MSSessionTracker *sessionTracker;

@property(atomic, getter=isAutoPageTrackingEnabled) BOOL autoPageTrackingEnabled;

@property(nonatomic, nullable) id<MSAnalyticsDelegate> delegate;

@property(nonatomic) NSUInteger flushInterval;

/**
 * Transmission targets.
 */
@property(nonatomic) NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *> *transmissionTargets;

/**
 * Default transmission target.
 */
@property(nonatomic) MSAnalyticsTransmissionTarget *defaultTransmissionTarget;

/**
 * The channel unit for common schema logs.
 */
@property(nonatomic, nullable) id<MSChannelUnitProtocol> oneCollectorChannelUnit;

/**
 * The channel unit for critical common schema logs.
 */
@property(nonatomic, nullable) id<MSChannelUnitProtocol> oneCollectorCriticalChannelUnit;

/**
 * Critical events channel unit.
 */
@property(nonatomic) id<MSChannelUnitProtocol> criticalChannelUnit;

/**
 * Track an event.
 *
 * @param eventName  Event name.
 * @param properties Dictionary of properties.
 * @param transmissionTarget Transmission target to associate with the event.
 * @param flags      Optional flags. Events tracked with the MSFlagsCritical flag will take precedence over all other events in
 * storage. An event tracked with this option will only be dropped if storage must make room for a newer event that is also marked with the
 * MSFlagsCritical flag.
 */
- (void)trackEvent:(NSString *)eventName
           withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties
    forTransmissionTarget:(nullable MSAnalyticsTransmissionTarget *)transmissionTarget
                    flags:(MSFlags)flags;

/**
 * Track an event with typed properties.
 *
 * @param eventName  Event name.
 * @param properties Typed properties.
 * @param transmissionTarget Transmission target to associate with the event.
 * @param flags      Optional flags. Events tracked with the MSFlagsCritical flag will take precedence over all other events in
 * storage. An event tracked with this option will only be dropped if storage must make room for a newer event that is also marked with the
 * MSFlagsCritical flag.
 */
- (void)trackEvent:(NSString *)eventName
      withTypedProperties:(nullable MSEventProperties *)properties
    forTransmissionTarget:(nullable MSAnalyticsTransmissionTarget *)transmissionTarget
                    flags:(MSFlags)flags;

/**
 * Track a page.
 *
 * @param pageName  Page name.
 * @param properties Dictionary of properties.
 */
- (void)trackPage:(NSString *)pageName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

/**
 * Get a transmissionTarget.
 *
 * @param token The token of the transmission target to retrieve.
 *
 * @returns The transmission target object.
 */
- (MSAnalyticsTransmissionTarget *)transmissionTargetForToken:(NSString *)token;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

/**
 * Removes properties with keys that are not a string or that have non-string values.
 *
 * @param properties A dictionary of properties.
 *
 * @returns A dictionary of valid properties or an empty dictionay.
 */
- (NSDictionary<NSString *, NSString *> *)removeInvalidProperties:(NSDictionary<NSString *, NSString *> *)properties;

@end

NS_ASSUME_NONNULL_END
