#import "MSAnalyticsInternal.h"
#import "MSAnalyticsAuthenticationProviderInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSCommonSchemaLog.h"
#import "MSLogger.h"
#import "MSPropertyConfiguratorPrivate.h"
#import "MSServiceAbstractInternal.h"
#import "MSUtility+StringFormatting.h"

@implementation MSAnalyticsTransmissionTarget

static id _authenticationProvider;

- (instancetype)
initWithTransmissionTargetToken:(NSString *)token
                   parentTarget:(MSAnalyticsTransmissionTarget *)parentTarget
                   channelGroup:(id<MSChannelGroupProtocol>)channelGroup {
  if ((self = [super init])) {
    _propertyConfigurator =
        [[MSPropertyConfigurator alloc] initWithTransmissionTarget:self];
    _channelGroup = channelGroup;
    _parentTarget = parentTarget;
    _childTransmissionTargets =
        [NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *> new];
    _transmissionTargetToken = token;
    _isEnabledKey = [NSString
        stringWithFormat:@"%@/%@", [MSAnalytics sharedInstance].isEnabledKey,
                         [MSUtility targetIdFromTargetToken:token]];
    // Disable if ancestor is disabled.
    if (![self isImmediateParent]) {
      [MS_USER_DEFAULTS setObject:@(NO) forKey:self.isEnabledKey];
    }

    // Add property configurator to the channel group as a delegate.
    [_channelGroup addDelegate:_propertyConfigurator];

    // Add self to channel group as delegate to decorate logs with tickets.
    [_channelGroup addDelegate:self];
  }
  return self;
}

+ (void)addAuthenticationProvider:
    (MSAnalyticsAuthenticationProvider *)authenticationProvider {
  @synchronized(self) {
    if (!authenticationProvider) {
      MSLogError([MSAnalytics logTag],
                 @"Authentication provider may not be null.");
      return;
    }

    /*
     * No need to validate the authentication provider's properties as they are
     * required for initialization and can't be null.
     */
    self.authenticationProvider = authenticationProvider;

    // Request token now.
    [self.authenticationProvider acquireTokenAsync];
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
- (void)trackEvent:(NSString *)eventName
    withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  NSMutableDictionary *mergedProperties = [NSMutableDictionary new];

  // Merge properties in its ancestors.
  MSAnalyticsTransmissionTarget *target = self;
  while (target != nil) {
    [target mergeEventPropertiesWith:mergedProperties];
    target = target.parentTarget;
  }

  // Override properties.
  if (properties) {
    [mergedProperties
        addEntriesFromDictionary:(NSDictionary * _Nonnull)properties];
  } else if ([mergedProperties count] == 0) {

    // Set nil for the properties to pass nil to trackEvent.
    mergedProperties = nil;
  }
  [MSAnalytics trackEvent:eventName
             withProperties:mergedProperties
      forTransmissionTarget:self];
}

- (MSAnalyticsTransmissionTarget *)transmissionTargetForToken:
    (NSString *)token {

  // Look up for the token in the dictionary, create a new transmission target
  // if doesn't exist.
  MSAnalyticsTransmissionTarget *target = self.childTransmissionTargets[token];
  if (!target) {
    target = [[MSAnalyticsTransmissionTarget alloc]
        initWithTransmissionTargetToken:token
                           parentTarget:self
                           channelGroup:self.channelGroup];
    self.childTransmissionTargets[token] = target;
  }
  return target;
}

- (BOOL)isEnabled {
  @synchronized([MSAnalytics sharedInstance]) {

    // Get isEnabled value from persistence.
    // No need to cache the value in a property, user settings already have
    // their cache mechanism.
    NSNumber *isEnabledNumber =
        [MS_USER_DEFAULTS objectForKey:self.isEnabledKey];

    // Return the persisted value otherwise it's enabled by default.
    return (isEnabledNumber) ? [isEnabledNumber boolValue] : YES;
  }
}

- (void)setEnabled:(BOOL)isEnabled {
  @synchronized([MSAnalytics sharedInstance]) {
    if (self.isEnabled != isEnabled) {

      // Don't enable if the immediate parent is disabled.
      if (isEnabled && ![self isImmediateParent]) {
        MSLogWarning([MSAnalytics logTag], @"Can't enable; parent transmission "
                                           @"target and/or Analytics service "
                                           @"is disabled.");
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

#pragma mark - ChannelDelegate callbacks

- (void)channel:(id<MSChannelProtocol>)__unused channel
     prepareLog:(id<MSLog>)log {

  /*
   * Only set ticketKey for owned target. Not strictly necessary but this avoids
   * setting the ticketKeyHash multiple times for a log.
   */
  if (![log.transmissionTargetTokens
          containsObject:self.transmissionTargetToken]) {
    return;
  }
  if ([log isKindOfClass:[MSCommonSchemaLog class]] && [self isEnabled]) {
    if (MSAnalyticsTransmissionTarget.authenticationProvider) {
      NSString *ticketKeyHash =
          MSAnalyticsTransmissionTarget.authenticationProvider.ticketKeyHash;
      ((MSCommonSchemaLog *)log).ext.protocolExt.ticketKeys =
          @[ ticketKeyHash ];
      [MSAnalyticsTransmissionTarget.authenticationProvider checkTokenExpiry];
    }
  }
}

#pragma mark - Private methods

+ (MSAnalyticsAuthenticationProvider *)authenticationProvider {
  @synchronized(self) {
    return _authenticationProvider;
  }
}

+ (void)setAuthenticationProvider:
    (MSAnalyticsAuthenticationProvider *)authenticationProvider {
  @synchronized(self) {
    _authenticationProvider = authenticationProvider;
  }
}

- (void)mergeEventPropertiesWith:
    (NSMutableDictionary<NSString *, NSString *> *)mergedProperties {
  @synchronized([MSAnalytics sharedInstance]) {
    for (NSString *key in self.propertyConfigurator.eventProperties) {
      if ([mergedProperties objectForKey:key] == nil) {
        NSString *value =
            [self.propertyConfigurator.eventProperties objectForKey:key];
        [mergedProperties setObject:value forKey:key];
      }
    }
  }
}

/**
 * Check ancestor enabled state, the ancestor is either the immediate target
 * parent if there is one or Analytics.
 *
 * @return YES if the immediate ancestor is enabled.
 */
- (BOOL)isImmediateParent {
  return self.parentTarget ? self.parentTarget.isEnabled
                           : [MSAnalytics isEnabled];
}

@end
