#import "MSAnalytics.h"
#import "MSAnalytics+Validation.h"
#import "MSAnalyticsCategory.h"
#import "MSAnalyticsPrivate.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSConstants+Internal.h"
#import "MSEventLog.h"
#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"
#import "MSPageLog.h"
#import "MSServiceAbstractProtected.h"
#import "MSSessionContext.h"
#import "MSStringTypedProperty.h"
#import "MSTypedProperty.h"
#import "MSUserIdContext.h"
#import "MSUtility+StringFormatting.h"

// Service name for initialization.
static NSString *const kMSServiceName = @"Analytics";

// The group Id for storage.
static NSString *const kMSGroupId = @"Analytics";

// Singleton
static MSAnalytics *sharedInstance = nil;
static dispatch_once_t onceToken;

@implementation MSAnalytics

/**
 * @discussion
 * Workaround for exporting symbols from category object files.
 * See article
 * https://medium.com/ios-os-x-development/categories-in-static-libraries-78e41f8ddb96#.aedfl1kl0
 */
__attribute__((used)) static void importCategories() { [NSString stringWithFormat:@"%@", MSAnalyticsValidationCategory]; }

@synthesize autoPageTrackingEnabled = _autoPageTrackingEnabled;
@synthesize channelUnitConfiguration = _channelUnitConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {

    // Set defaults.
    _autoPageTrackingEnabled = NO;

    // Init session tracker.
    _sessionTracker = [[MSSessionTracker alloc] init];
    _sessionTracker.delegate = self;

    // Init channel configuration.
    _channelUnitConfiguration = [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];

    // Set up transmission target dictionary.
    _transmissionTargets = [NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *> new];
  }
  return self;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[MSAnalytics alloc] init];
    }
  });
  return sharedInstance;
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
  if (token) {

    /*
     * Don't use [self transmissionTargetForToken] because that will add the default transmission target to the cache, but it should be
     * separate.
     */
    self.defaultTransmissionTarget = [self createTransmissionTargetForToken:token];
  }

  // Set up swizzling for auto page tracking.
  [MSAnalyticsCategory activateCategory];
  MSLogVerbose([MSAnalytics logTag], @"Started Analytics service.");
}

+ (NSString *)logTag {
  return @"AppCenterAnalytics";
}

- (NSString *)groupId {
  return kMSGroupId;
}

#pragma mark - MSServiceAbstract

- (void)setEnabled:(BOOL)isEnabled {
  [super setEnabled:isEnabled];

  // Propagate to transmission targets.
  for (NSString *token in self.transmissionTargets) {
    [self.transmissionTargets[token] setEnabled:isEnabled];
  }
}

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {
    if (self.startedFromApplication) {
      [self resume];

      // Start session tracker.
      [self.sessionTracker start];

      // Add delegates to log manager.
      [self.channelGroup addDelegate:self.sessionTracker];
      [self.channelGroup addDelegate:self];

      // Report current page while auto page tracking is on.
      if (self.autoPageTrackingEnabled) {

        // Track on the main queue to avoid race condition with page swizzling.
        dispatch_async(dispatch_get_main_queue(), ^{
          if ([[MSAnalyticsCategory missedPageViewName] length] > 0) {
            [[self class] trackPage:(NSString *)[MSAnalyticsCategory missedPageViewName]];
          }
        });
      }
    }

    MSLogInfo([MSAnalytics logTag], @"Analytics service has been enabled.");
  } else {
    if (self.startedFromApplication) {
      [self.channelGroup removeDelegate:self.sessionTracker];
      [self.channelGroup removeDelegate:self];
      [self.sessionTracker stop];
      [[MSSessionContext sharedInstance] clearSessionHistoryAndKeepCurrentSession:NO];
    }
    MSLogInfo([MSAnalytics logTag], @"Analytics service has been disabled.");
  }
}

- (BOOL)isAppSecretRequired {
  return NO;
}

- (void)updateConfigurationWithAppSecret:(NSString *)appSecret transmissionTargetToken:(NSString *)token {
  [super updateConfigurationWithAppSecret:appSecret transmissionTargetToken:token];

  // Create the default target if not already created in start.
  if (token && !self.defaultTransmissionTarget) {

    /*
     * Don't use [self transmissionTargetForToken] because that will add the default transmission target to the cache, but it should be
     * separate.
     */
    self.defaultTransmissionTarget = [self createTransmissionTargetForToken:token];
  }
}

#pragma mark - Service methods

+ (void)trackEvent:(NSString *)eventName {
  [self trackEvent:eventName withProperties:nil];
}

+ (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  [self trackEvent:eventName withProperties:properties flags:MSFlagsDefault];
}

+ (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties flags:(MSFlags)flags {
  [self trackEvent:eventName withProperties:properties forTransmissionTarget:nil flags:flags];
}

+ (void)trackEvent:(NSString *)eventName withTypedProperties:(nullable MSEventProperties *)properties {
  [self trackEvent:eventName withTypedProperties:properties flags:MSFlagsDefault];
}

+ (void)trackEvent:(NSString *)eventName withTypedProperties:(nullable MSEventProperties *)properties flags:(MSFlags)flags {
  [self trackEvent:eventName withTypedProperties:properties forTransmissionTarget:nil flags:flags];
}

+ (void)trackEvent:(NSString *)eventName
           withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties
    forTransmissionTarget:(nullable MSAnalyticsTransmissionTarget *)transmissionTarget
                    flags:(MSFlags)flags {
  @synchronized(self) {
    if ([[MSAnalytics sharedInstance] canBeUsed]) {
      [[MSAnalytics sharedInstance] trackEvent:eventName withProperties:properties forTransmissionTarget:transmissionTarget flags:flags];
    }
  }
}

+ (void)trackEvent:(NSString *)eventName
      withTypedProperties:(nullable MSEventProperties *)properties
    forTransmissionTarget:(nullable MSAnalyticsTransmissionTarget *)transmissionTarget
                    flags:(MSFlags)flags {
  @synchronized(self) {
    if ([[MSAnalytics sharedInstance] canBeUsed]) {
      [[MSAnalytics sharedInstance] trackEvent:eventName
                           withTypedProperties:properties
                         forTransmissionTarget:transmissionTarget
                                         flags:flags];
    }
  }
}

+ (void)trackPage:(NSString *)pageName {
  [self trackPage:pageName withProperties:nil];
}

+ (void)trackPage:(NSString *)pageName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  @synchronized(self) {
    if ([[MSAnalytics sharedInstance] canBeUsed]) {
      [[MSAnalytics sharedInstance] trackPage:pageName withProperties:properties];
    }
  }
}

+ (void)pause {
  @synchronized(self) {
    if ([[MSAnalytics sharedInstance] canBeUsed]) {
      [[MSAnalytics sharedInstance] pause];
    }
  }
}

+ (void)resume {
  @synchronized(self) {
    if ([[MSAnalytics sharedInstance] canBeUsed]) {
      [[MSAnalytics sharedInstance] resume];
    }
  }
}

+ (void)setAutoPageTrackingEnabled:(BOOL)isEnabled {
  @synchronized(self) {
    [[MSAnalytics sharedInstance] setAutoPageTrackingEnabled:isEnabled];
  }
}

+ (BOOL)isAutoPageTrackingEnabled {
  @synchronized(self) {
    return [[MSAnalytics sharedInstance] isAutoPageTrackingEnabled];
  }
}

#pragma mark - Transmission Target

+ (MSAnalyticsTransmissionTarget *)transmissionTargetForToken:(NSString *)token {
  return [[MSAnalytics sharedInstance] transmissionTargetForToken:token];
}

+ (void)pauseTransmissionTargetForToken:(NSString *)token {
  [[MSAnalytics sharedInstance] pauseTransmissionTargetForToken:token];
}

+ (void)resumeTransmissionTargetForToken:(NSString *)token {
  [[MSAnalytics sharedInstance] resumeTransmissionTargetForToken:token];
}

#pragma mark - Private methods

- (void)trackEvent:(NSString *)eventName
           withProperties:(NSDictionary<NSString *, NSString *> *)properties
    forTransmissionTarget:(MSAnalyticsTransmissionTarget *)transmissionTarget
                    flags:(MSFlags)flags {
  NSDictionary *validProperties = [self removeInvalidProperties:properties];
  MSEventProperties *eventProperties = [[MSEventProperties alloc] initWithStringDictionary:validProperties];
  [self trackEvent:eventName withTypedProperties:eventProperties forTransmissionTarget:transmissionTarget flags:flags];
}

- (void)trackEvent:(NSString *)eventName
      withTypedProperties:(MSEventProperties *)properties
    forTransmissionTarget:(MSAnalyticsTransmissionTarget *)transmissionTarget
                    flags:(MSFlags)flags {
  if (![self isEnabled]) {
    return;
  }

  // Use default transmission target if no transmission target was provided.
  if (transmissionTarget == nil) {
    transmissionTarget = self.defaultTransmissionTarget;
  }

  // Validate flags.
  MSFlags persistenceFlag = flags & kMSPersistenceFlagsMask;
  if (persistenceFlag != MSFlagsPersistenceNormal && persistenceFlag != MSFlagsPersistenceCritical) {
    MSLogWarning([MSAnalytics logTag], @"Invalid flags (%u) received, using normal as a default.", (unsigned int)persistenceFlag);
    persistenceFlag = MSFlagsPersistenceNormal;
  }

  // Create an event log.
  MSEventLog *log = [MSEventLog new];

  // Add transmission target token.
  if (transmissionTarget) {
    if (transmissionTarget.isEnabled) {
      [log addTransmissionTargetToken:[transmissionTarget transmissionTargetToken]];
      log.tag = transmissionTarget;
      if (transmissionTarget == self.defaultTransmissionTarget) {
        log.userId = [[MSUserIdContext sharedInstance] userId];
      }
    } else {
      MSLogError([MSAnalytics logTag], @"This transmission target is disabled.");
      return;
    }
  }

  // Set properties of the event log.
  log.name = eventName;
  log.eventId = MS_UUID_STRING;
  if (!self.defaultTransmissionTarget) {
    properties = [self validateAppCenterEventProperties:properties];
  }
  log.typedProperties = [properties isEmpty] ? nil : properties;

  // Send log to channel.
  [self sendLog:log flags:persistenceFlag];
}

- (void)pause {
  [self.channelUnit pauseWithIdentifyingObject:self];
}

- (void)resume {
  [self.channelUnit resumeWithIdentifyingObject:self];
}

- (NSDictionary<NSString *, NSString *> *)removeInvalidProperties:(NSDictionary<NSString *, NSString *> *)properties {
  NSMutableDictionary<NSString *, id> *validProperties = [NSMutableDictionary new];
  for (NSString *key in properties) {
    if (![key isKindOfClass:[NSString class]]) {
      MSLogWarning([MSAnalytics logTag], @"Event property contains an invalid key, dropping the property.");
      continue;
    }

    // We have a valid key, so let's validate the value.
    id value = properties[key];
    if (value) {

      // Not checking for empty string, as values can be empty strings.
      if ([(NSObject *)value isKindOfClass:[NSString class]]) {
        [validProperties setValue:value forKey:key];
      }
    } else {
      MSLogWarning([MSAnalytics logTag], @"Event property contains an invalid value for key %@, dropping the property.", key);
    }
  }

  return validProperties;
}

- (void)trackPage:(NSString *)pageName withProperties:(NSDictionary<NSString *, NSString *> *)properties {
  if (![self isEnabled]) {
    return;
  }

  // Create an event log.
  MSPageLog *log = [MSPageLog new];

  // Set properties of the event log.
  log.name = pageName;
  if (properties && properties.count > 0) {
    log.properties = [self removeInvalidProperties:properties];
  }

  // Send log to log manager.
  [self sendLog:log flags:MSFlagsDefault];
}

- (void)setAutoPageTrackingEnabled:(BOOL)isEnabled {
  _autoPageTrackingEnabled = isEnabled;
}

- (BOOL)isAutoPageTrackingEnabled {
  return self.autoPageTrackingEnabled;
}

- (void)sendLog:(id<MSLog>)log flags:(MSFlags)flags {

  // Send log to log manager.
  [self.channelUnit enqueueItem:log flags:flags];
}

- (MSAnalyticsTransmissionTarget *)transmissionTargetForToken:(NSString *)transmissionTargetToken {
  MSAnalyticsTransmissionTarget *transmissionTarget = self.transmissionTargets[transmissionTargetToken];
  if (transmissionTarget) {
    MSLogDebug([MSAnalytics logTag], @"Returning transmission target found with id %@.",
               [MSUtility targetKeyFromTargetToken:transmissionTargetToken]);
    return transmissionTarget;
  }
  transmissionTarget = [self createTransmissionTargetForToken:transmissionTargetToken];
  self.transmissionTargets[transmissionTargetToken] = transmissionTarget;

  // TODO: Start service if not already.
  // Scenario: getTransmissionTarget gets called before App Center has an app
  // secret or transmission target but start has been called for this service.
  return transmissionTarget;
}

- (MSAnalyticsTransmissionTarget *)createTransmissionTargetForToken:(NSString *)transmissionTargetToken {
  MSAnalyticsTransmissionTarget *target = [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:transmissionTargetToken
                                                                                                    parentTarget:nil
                                                                                                    channelGroup:self.channelGroup];
  MSLogDebug([MSAnalytics logTag], @"Created transmission target with target key %@.",
             [MSUtility targetKeyFromTargetToken:transmissionTargetToken]);
  return target;
}

- (void)pauseTransmissionTargetForToken:(NSString *)token {
  if (self.oneCollectorChannelUnit) {
    [self.oneCollectorChannelUnit pauseSendingLogsWithToken:token];
  }
}

- (void)resumeTransmissionTargetForToken:(NSString *)token {
  if (self.oneCollectorChannelUnit) {
    [self.oneCollectorChannelUnit resumeSendingLogsWithToken:token];
  }
}

- (id<MSChannelUnitProtocol>)oneCollectorChannelUnit {
  if (!_oneCollectorChannelUnit) {
    NSString *oneCollectorGroupId = [NSString stringWithFormat:@"%@%@", self.groupId, kMSOneCollectorGroupIdSuffix];
    self.oneCollectorChannelUnit = [self.channelGroup channelUnitForGroupId:oneCollectorGroupId];
  }
  return _oneCollectorChannelUnit;
}

+ (void)resetSharedInstance {

  // resets the once_token so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
}

#pragma mark - MSSessionTracker

- (void)sessionTracker:(id)sessionTracker processLog:(id<MSLog>)log {
  (void)sessionTracker;
  [self sendLog:log flags:MSFlagsDefault];
}

+ (void)setDelegate:(nullable id<MSAnalyticsDelegate>)delegate {
  [[MSAnalytics sharedInstance] setDelegate:delegate];
}

#pragma mark - MSChannelDelegate

- (void)channel:(id<MSChannelProtocol>)channel willSendLog:(id<MSLog>)log {
  (void)channel;
  if (!self.delegate) {
    return;
  }
  NSObject *logObject = (NSObject *)log;
  if ([logObject isKindOfClass:[MSEventLog class]] && [self.delegate respondsToSelector:@selector(analytics:willSendEventLog:)]) {
    MSEventLog *eventLog = (MSEventLog *)log;
    [self.delegate analytics:self willSendEventLog:eventLog];
  } else if ([logObject isKindOfClass:[MSPageLog class]] && [self.delegate respondsToSelector:@selector(analytics:willSendPageLog:)]) {
    MSPageLog *pageLog = (MSPageLog *)log;
    [self.delegate analytics:self willSendPageLog:pageLog];
  }
}

- (void)channel:(id<MSChannelProtocol>)channel didSucceedSendingLog:(id<MSLog>)log {
  (void)channel;
  if (!self.delegate) {
    return;
  }
  NSObject *logObject = (NSObject *)log;
  if ([logObject isKindOfClass:[MSEventLog class]] && [self.delegate respondsToSelector:@selector(analytics:didSucceedSendingEventLog:)]) {
    MSEventLog *eventLog = (MSEventLog *)log;
    [self.delegate analytics:self didSucceedSendingEventLog:eventLog];
  } else if ([logObject isKindOfClass:[MSPageLog class]] && [self.delegate respondsToSelector:@selector(analytics:
                                                                                                  didSucceedSendingPageLog:)]) {
    MSPageLog *pageLog = (MSPageLog *)log;
    [self.delegate analytics:self didSucceedSendingPageLog:pageLog];
  }
}

- (void)channel:(id<MSChannelProtocol>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  (void)channel;
  if (!self.delegate) {
    return;
  }
  NSObject *logObject = (NSObject *)log;
  if ([logObject isKindOfClass:[MSEventLog class]] && [self.delegate respondsToSelector:@selector(analytics:
                                                                                            didFailSendingEventLog:withError:)]) {
    MSEventLog *eventLog = (MSEventLog *)log;
    [self.delegate analytics:self didFailSendingEventLog:eventLog withError:error];
  } else if ([logObject isKindOfClass:[MSPageLog class]] && [self.delegate respondsToSelector:@selector(analytics:
                                                                                                  didFailSendingPageLog:withError:)]) {
    MSPageLog *pageLog = (MSPageLog *)log;
    [self.delegate analytics:self didFailSendingPageLog:pageLog withError:error];
  }
}

@end
