#import "MSAnalyticsInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSLogger.h"
#import "MSServiceAbstractInternal.h"
#import "MSUtility+StringFormatting.h"

@implementation MSAnalyticsTransmissionTarget

- (instancetype)initWithTransmissionTargetToken:(NSString *)token
                                   parentTarget:(nullable MSAnalyticsTransmissionTarget *)parentTarget
                                        storage:(MSUserDefaults *)storage {
  if ((self = [super init])) {
    _storage = storage;
    _parentTarget = parentTarget;
    _childTransmissionTargets = [NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *> new];
    _transmissionTargetToken = token;
    _isEnabledKey = [NSString stringWithFormat:@"%@/%@", [MSAnalytics sharedInstance].isEnabledKey,
                                               [MSUtility targetIdFromTargetToken:token]];

    // Disable if ancestor is disabled.
    if (![self isAncestorEnabled]) {
      [_storage setObject:@(NO) forKey:self.isEnabledKey];
      ;
    }
  }
  return self;
}

- (instancetype)initWithTransmissionTargetToken:(NSString *)token
                                   parentTarget:(MSAnalyticsTransmissionTarget *)parentTarget {
  return [self initWithTransmissionTargetToken:token parentTarget:parentTarget storage:MS_USER_DEFAULTS];
}

/**
 * Track an event.
 *
 * @param eventName  event name.
 */
- (void)trackEvent:(NSString *)eventName {
  [MSAnalytics trackEvent:eventName forTransmissionTarget:self];
}

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 */
- (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  [MSAnalytics trackEvent:eventName withProperties:properties forTransmissionTarget:self];
}

- (MSAnalyticsTransmissionTarget *)transmissionTargetForToken:(NSString *)token {

  // Look up for the token in the dictionary, create a new transmission target if doesn't exist.
  MSAnalyticsTransmissionTarget *target = self.childTransmissionTargets[token];
  if (!target) {
    target = [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:token parentTarget:self];
    self.childTransmissionTargets[token] = target;
  }
  return target;
}

- (BOOL)isEnabled {

  // Get isEnabled value from persistence.
  // No need to cache the value in a property, user settings already have their cache mechanism.
  NSNumber *isEnabledNumber = [self.storage objectForKey:self.isEnabledKey];

  // Return the persisted value otherwise it's enabled by default.
  return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
}

- (void)setEnabled:(BOOL)isEnabled {
  if (self.isEnabled != isEnabled) {

    // Don't enable if the immediate parent is disabled.
    if (isEnabled && ![self isAncestorEnabled]) {
      MSLogWarning([MSAnalytics logTag],
                   @"Can't enable; parent transmission target and/or Analytics service is disabled.");
      return;
    }

    // Persist the enabled status.
    [self.storage setObject:@(isEnabled) forKey:self.isEnabledKey];
  }

  // Propagate to nested transmission targets. TODO Find a more effective approach.
  for (NSString *token in self.childTransmissionTargets) {
    [self.childTransmissionTargets[token] setEnabled:isEnabled];
  }
}

/**
 * Check ancestor enabled state, the ancestor is either the immediate target parent if there is one or Analytics.
 *
 * @return YES if the immediate ancestor is enabled.
 */
- (BOOL)isAncestorEnabled {
  return self.parentTarget ? self.parentTarget.isEnabled : [MSAnalytics isEnabled];
}

@end
