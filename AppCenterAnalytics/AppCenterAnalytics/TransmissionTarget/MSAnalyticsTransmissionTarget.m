#import "MSAnalyticsInternal.h"
#import "MSServiceAbstractInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSLogger.h"
#import "MSUtility+StringFormatting.h"

@implementation MSAnalyticsTransmissionTarget

- (instancetype)init {
  return [self initWithStorage:MS_USER_DEFAULTS];
}

- (instancetype)initWithStorage:(MSUserDefaults *)storage {
  if ((self = [super init])) {
    _storage = storage;
  }
  return self;
}

- (instancetype)initWithTransmissionTargetToken:(NSString *)token parentTarget:(MSAnalyticsTransmissionTarget *)parentTarget{
  if ((self = [self init])) {
    _parentTarget = parentTarget;
    _childTransmissionTargets = [NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *> new];
    _transmissionTargetToken = token;
    _isEnabledKey = [NSString stringWithFormat:@"%@/%@",[MSAnalytics sharedInstance].isEnabledKey, [MSUtility targetIdFromTargetToken:token]];
    
    // Match parent target or Analytics enabled state.
    [self setEnabled:[self isImmediateParentEnabled]];
  }
  return self;
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
    if (isEnabled && ![self isImmediateParentEnabled]){
      MSLogWarning([MSAnalytics logTag], @"Can't enable; parent transmission target and/or Analytics service is disabled.");
      return;
    }
    
    // Persist the enabled status.
    [self.storage setObject:@(isEnabled) forKey:self.isEnabledKey];
    
    // Propagate to nested transmission targets. TODO Find a more effective approach.
    for (NSString *token in self.childTransmissionTargets){
      [self.childTransmissionTargets[token] setEnabled:isEnabled];
    }
  }
}

/**
 * Check immediate parent enabled state.
 */
- (BOOL)isImmediateParentEnabled{
  
  // Check immediate parent or Analytics if no target parent.
  return self.parentTarget?self.parentTarget.isEnabled:[MSAnalytics isEnabled];
}

@end
