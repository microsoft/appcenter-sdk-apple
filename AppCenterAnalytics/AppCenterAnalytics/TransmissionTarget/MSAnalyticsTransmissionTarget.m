#import "MSAnalyticsAuthenticationProviderInternal.h"
#import "MSAnalyticsInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSCSExtensions.h"
#import "MSCommonSchemaLog.h"
#import "MSEventPropertiesInternal.h"
#import "MSLogger.h"
#import "MSPropertyConfiguratorInternal.h"
#import "MSProtocolExtension.h"
#import "MSServiceAbstractInternal.h"
#import "MSUtility+StringFormatting.h"

@implementation MSAnalyticsTransmissionTarget

static MSAnalyticsAuthenticationProvider *_authenticationProvider;

- (instancetype)initWithTransmissionTargetToken:(NSString *)token
                                   parentTarget:(MSAnalyticsTransmissionTarget *)parentTarget
                                   channelGroup:(id<MSChannelGroupProtocol>)channelGroup {
  if ((self = [super init])) {
    _propertyConfigurator = [[MSPropertyConfigurator alloc] initWithTransmissionTarget:self];
    _channelGroup = channelGroup;
    _parentTarget = parentTarget;
    _childTransmissionTargets = [NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *> new];
    _transmissionTargetToken = token;
    _isEnabledKey =
        [NSString stringWithFormat:@"%@/%@", [MSAnalytics sharedInstance].isEnabledKey, [MSUtility targetKeyFromTargetToken:token]];

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

+ (void)addAuthenticationProvider:(MSAnalyticsAuthenticationProvider *)authenticationProvider {
  @synchronized(self) {
    if (!authenticationProvider) {
      MSLogError([MSAnalytics logTag], @"Authentication provider may not be null.");
      return;
    }

    // No need to validate the authentication provider's properties as they are required for initialization and can't be null.
    self.authenticationProvider = authenticationProvider;

    // Request token now.
    [self.authenticationProvider acquireTokenAsync];
  }
}

- (void)trackEvent:(NSString *)eventName {
  [self trackEvent:eventName withProperties:nil];
}

- (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  [self trackEvent:eventName withProperties:properties flags:MSFlagsDefault];
}

- (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties flags:(MSFlags)flags {
  MSEventProperties *eventProperties;
  if (properties) {
    eventProperties = [MSEventProperties new];
    for (NSString *key in properties.allKeys) {
      NSString *value = properties[key];
      [eventProperties setString:value forKey:key];
    }
  }
  [self trackEvent:eventName withTypedProperties:eventProperties flags:flags];
}

- (void)trackEvent:(NSString *)eventName withTypedProperties:(nullable MSEventProperties *)properties {
  [self trackEvent:eventName withTypedProperties:properties flags:MSFlagsDefault];
}

- (void)trackEvent:(NSString *)eventName withTypedProperties:(nullable MSEventProperties *)properties flags:(MSFlags)flags {
  MSEventProperties *mergedProperties = [MSEventProperties new];

  // Merge properties in its ancestors.
  MSAnalyticsTransmissionTarget *target = self;
  while (target != nil) {
    [target.propertyConfigurator mergeTypedPropertiesWith:mergedProperties];
    target = target.parentTarget;
  }

  // Override properties.
  if (properties) {
    [mergedProperties mergeEventProperties:(MSEventProperties * __nonnull) properties];
  } else if ([mergedProperties isEmpty]) {

    // Set nil for the properties to pass nil to trackEvent.
    mergedProperties = nil;
  }
  [MSAnalytics trackEvent:eventName withTypedProperties:mergedProperties forTransmissionTarget:self flags:flags];
}

- (MSAnalyticsTransmissionTarget *)transmissionTargetForToken:(NSString *)token {

  // Look up for the token in the dictionary, create a new transmission target if doesn't exist.
  MSAnalyticsTransmissionTarget *target = self.childTransmissionTargets[token];
  if (!target) {
    target = [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:token parentTarget:self channelGroup:self.channelGroup];
    self.childTransmissionTargets[token] = target;
  }
  return target;
}

- (BOOL)isEnabled {
  @synchronized([MSAnalytics sharedInstance]) {

    // Get isEnabled value from persistence. No need to cache the value in a property, user settings already have their cache mechanism.
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
        MSLogWarning([MSAnalytics logTag], @"Can't enable; parent transmission "
                                           @"target and/or Analytics service "
                                           @"is disabled.");
        return;
      }

      // Persist the enabled status.
      [MS_USER_DEFAULTS setObject:@(isEnabled) forKey:self.isEnabledKey];

      if (isEnabled) {

        // Resume the target on enable
        [self resume];
      }
    }

    // Propagate to nested transmission targets.
    for (NSString *token in self.childTransmissionTargets) {
      [self.childTransmissionTargets[token] setEnabled:isEnabled];
    }
  }
}

- (void)pause {
  if (self.isEnabled) {
    [MSAnalytics pauseTransmissionTargetForToken:self.transmissionTargetToken];
  } else {
    MSLogError([MSAnalytics logTag], @"This transmission target is disabled.");
  }
}

- (void)resume {
  if (self.isEnabled) {
    [MSAnalytics resumeTransmissionTargetForToken:self.transmissionTargetToken];
  } else {
    MSLogError([MSAnalytics logTag], @"This transmission target is disabled.");
  }
}

#pragma mark - ChannelDelegate callbacks

- (void)channel:(id<MSChannelProtocol>)__unused channel prepareLog:(id<MSLog>)log {

  // Only set ticketKey for owned target. Not strictly necessary but this avoids setting the ticketKeyHash multiple times for a log.
  if (![log.transmissionTargetTokens containsObject:self.transmissionTargetToken]) {
    return;
  }
  if ([log isKindOfClass:[MSCommonSchemaLog class]] && [self isEnabled]) {
    if (MSAnalyticsTransmissionTarget.authenticationProvider) {
      NSString *ticketKeyHash = MSAnalyticsTransmissionTarget.authenticationProvider.ticketKeyHash;
      ((MSCommonSchemaLog *)log).ext.protocolExt.ticketKeys = @[ ticketKeyHash ];
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

+ (void)setAuthenticationProvider:(MSAnalyticsAuthenticationProvider *)authenticationProvider {
  @synchronized(self) {
    _authenticationProvider = authenticationProvider;
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
