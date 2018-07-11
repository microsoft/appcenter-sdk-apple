#import "MSAnalyticsInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSLogger.h"
#import "MSServiceAbstractInternal.h"
#import "MSUtility+StringFormatting.h"

@implementation MSAnalyticsTransmissionTarget

- (instancetype)initWithTransmissionTargetToken:(NSString *)token
                                   parentTarget:(MSAnalyticsTransmissionTarget *)parentTarget {
  if ((self = [super init])) {
    _parentTarget = parentTarget;
    _childTransmissionTargets = [NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *> new];
    _transmissionTargetToken = token;
    _isEnabledKey = [NSString stringWithFormat:@"%@/%@", [MSAnalytics sharedInstance].isEnabledKey,
                                               [MSUtility targetIdFromTargetToken:token]];
    _eventProperties = [NSMutableDictionary<NSString *, NSString *> new];

    // Disable if ancestor is disabled.
    if (![self isImmediateParent]) {
      [MS_USER_DEFAULTS setObject:@(NO) forKey:self.isEnabledKey];
    }
  }
  return self;
}

- (void)setEventPropertyString:(NSString *)propertyValue forKey:(NSString *)propertyKey {
  @synchronized([MSAnalytics sharedInstance]) {
    if (!propertyValue || !propertyKey) {
      MSLogError([MSAnalytics logTag], @"Event property keys and values cannot be nil.");
      return;
    }
    self.eventProperties[propertyKey] = propertyValue;
  }
}

- (void)removeEventPropertyforKey:(NSString *)propertyKey {
  @synchronized([MSAnalytics sharedInstance]) {
    if (!propertyKey) {
      MSLogError([MSAnalytics logTag], @"Event property key to remove cannot be nil.");
      return;
    }
    [self.eventProperties removeObjectForKey:propertyKey];
  }
}

/**
 * Track an event.
 *
 * @param eventName  event name.
 */
- (void)trackEvent:(NSString *)eventName {
  [self trackEvent:eventName withProperties:nil];
}

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 */
- (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  @synchronized([MSAnalytics sharedInstance]) {
    NSMutableDictionary *mergedProperties = [NSMutableDictionary new];

    // Merge properties in its ancestors.
    MSAnalyticsTransmissionTarget *target = self;
    while (target != nil) {
      [target mergeEventPropertiesWith:mergedProperties];
      target = target.parentTarget;
    }

    // Override properties.
    if (properties) {
      [mergedProperties addEntriesFromDictionary:(NSDictionary * _Nonnull)properties];
    } else if ([mergedProperties count] == 0) {

      // Set nil for the properties to pass nil to trackEvent.
      mergedProperties = nil;
    }
    [MSAnalytics trackEvent:eventName withProperties:mergedProperties forTransmissionTarget:self];
  }
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
  @synchronized([MSAnalytics sharedInstance]) {

    // Get isEnabled value from persistence.
    // No need to cache the value in a property, user settings already have their cache mechanism.
    NSNumber *isEnabledNumber = [MS_USER_DEFAULTS objectForKey:self.isEnabledKey];

    // Return the persisted value otherwise it's enabled by default.
    return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
  }
}

- (void)setEnabled:(BOOL)isEnabled {
  @synchronized([MSAnalytics sharedInstance]) {
    if (self.isEnabled != isEnabled) {

      // Don't enable if the immediate parent is disabled.
      if (isEnabled && ![self isImmediateParent]) {
        MSLogWarning([MSAnalytics logTag],
                     @"Can't enable; parent transmission target and/or Analytics service is disabled.");
        return;
      }

      // Persist the enabled status.
      [MS_USER_DEFAULTS setObject:@(isEnabled) forKey:self.isEnabledKey];
    }

    // Propagate to nested transmission targets.
    for (NSString *token in self.childTransmissionTargets) {
      [self.childTransmissionTargets[token] setEnabled:isEnabled];
    }
  }
}

- (void)mergeEventPropertiesWith:(NSMutableDictionary<NSString *, NSString *> *)mergedProperties {
  for (NSString *key in self.eventProperties) {
    if ([mergedProperties objectForKey:key] == nil) {
      NSString *value = [self.eventProperties objectForKey:key];
      [mergedProperties setObject:value forKey:key];
    }
  }
}

/**
 * Check ancestor enabled state, the ancestor is either the immediate target parent if there is one or Analytics.
 *
 * @return YES if the immediate ancestor is enabled.
 */
- (BOOL)isImmediateParent {
  return self.parentTarget ? self.parentTarget.isEnabled : [MSAnalytics isEnabled];
}

@end
