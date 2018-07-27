#import "MSAnalytics.h"
#import "MSAnalytics+Validation.h"
#import "MSAnalyticsCategory.h"
#import "MSAnalyticsInternal.h"
#import "MSAnalyticsPrivate.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSConstants+Internal.h"
#import "MSEventLog.h"
#import "MSPageLog.h"
#import "MSServiceAbstractProtected.h"
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
__attribute__((used)) static void importCategories() {
  [NSString stringWithFormat:@"%@", MSAnalyticsValidationCategory];
}

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
    _channelUnitConfiguration = [[MSChannelUnitConfiguration alloc]
        initDefaultConfigurationWithGroupId:[self groupId]];

    // Set up transmission target dictionary.
    _transmissionTargets =
        [NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *> new];
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
  [super startWithChannelGroup:channelGroup
                     appSecret:appSecret
       transmissionTargetToken:token
               fromApplication:fromApplication];
  if (token) {
    self.defaultTransmissionTarget =
        [self transmissionTargetFor:(NSString *)token];
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
            [[self class]
                trackPage:(NSString *
                           _Nonnull)[MSAnalyticsCategory missedPageViewName]];
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
    }
    MSLogInfo([MSAnalytics logTag], @"Analytics service has been disabled.");
  }
}

- (BOOL)isAppSecretRequired {
  return NO;
}

- (void)updateConfigurationWithAppSecret:(NSString *)appSecret
                 transmissionTargetToken:(NSString *)token {
  [super updateConfigurationWithAppSecret:appSecret
                  transmissionTargetToken:token];

  // Create the default target if not already created in start.
  if (token && !self.defaultTransmissionTarget) {
    self.defaultTransmissionTarget =
        [self transmissionTargetFor:(NSString *)token];
  }
}

#pragma mark - Service methods

+ (void)trackEvent:(NSString *)eventName {
  [self trackEvent:eventName withProperties:nil];
}

+ (void)trackEvent:(NSString *)eventName
    withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  [self trackEvent:eventName
             withProperties:properties
      forTransmissionTarget:nil];
}

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 * @param transmissionTarget  the transmission target to associate to this
 * event.
 */
+ (void)trackEvent:(NSString *)eventName
           withProperties:
               (nullable NSDictionary<NSString *, NSString *> *)properties
    forTransmissionTarget:
        (nullable MSAnalyticsTransmissionTarget *)transmissionTarget {
  @synchronized(self) {
    if ([[MSAnalytics sharedInstance] canBeUsed]) {
      [[MSAnalytics sharedInstance] trackEvent:eventName
                                withProperties:properties
                         forTransmissionTarget:transmissionTarget];
    }
  }
}

+ (void)trackPage:(NSString *)pageName {
  [self trackPage:pageName withProperties:nil];
}

+ (void)trackPage:(NSString *)pageName
    withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  @synchronized(self) {
    if ([[MSAnalytics sharedInstance] canBeUsed]) {
      [[MSAnalytics sharedInstance] trackPage:pageName
                               withProperties:properties];
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

#pragma mark - Private methods

- (void)trackEvent:(NSString *)eventName
           withProperties:(NSDictionary<NSString *, NSString *> *)properties
    forTransmissionTarget:(MSAnalyticsTransmissionTarget *)transmissionTarget {
  if (![self isEnabled]) {
    return;
  }

  // Use default transmission target if no transmission target was provided.
  if (transmissionTarget == nil) {
    transmissionTarget = self.defaultTransmissionTarget;
  }

  // Create an event log.
  MSEventLog *log = [MSEventLog new];

  // Add transmission target token.
  if (transmissionTarget) {
    if (transmissionTarget.isEnabled) {
      [log addTransmissionTargetToken:[transmissionTarget
                                          transmissionTargetToken]];
    } else {
      MSLogError([MSAnalytics logTag],
                 @"This transmission target is disabled.");
    }
  }

  // Set properties of the event log.
  log.name = eventName;
  log.eventId = MS_UUID_STRING;
  if (properties && properties.count > 0) {
    log.properties = [properties copy];
  }

  // Send log to log manager.
  [self sendLog:log];
}

- (void)trackPage:(NSString *)pageName
    withProperties:(NSDictionary<NSString *, NSString *> *)properties {
  if (![self isEnabled]) {
    return;
  }

  // Create an event log.
  MSPageLog *log = [MSPageLog new];

  // Set properties of the event log.
  log.name = pageName;
  if (properties && properties.count > 0) {
    log.properties = [properties copy];
  }

  // Send log to log manager.
  [self sendLog:log];
}

- (void)setAutoPageTrackingEnabled:(BOOL)isEnabled {
  _autoPageTrackingEnabled = isEnabled;
}

- (BOOL)isAutoPageTrackingEnabled {
  return self.autoPageTrackingEnabled;
}

- (void)sendLog:(id<MSLog>)log {

  // Send log to log manager.
  [self.channelUnit enqueueItem:log];
}

/**
 * Get a transmission target.
 *
 * @param transmissionTargetToken token of the transmission target to retrieve.
 *
 * @returns The transmission target object.
 */
- (MSAnalyticsTransmissionTarget *)transmissionTargetFor:
    (NSString *)transmissionTargetToken {
  MSAnalyticsTransmissionTarget *transmissionTarget =
      [self.transmissionTargets objectForKey:transmissionTargetToken];
  if (transmissionTarget) {
    MSLogDebug([MSAnalytics logTag],
               @"Returning transmission target found with id %@.",
               [MSUtility targetIdFromTargetToken:transmissionTargetToken]);
    return transmissionTarget;
  }
  transmissionTarget = [[MSAnalyticsTransmissionTarget alloc]
      initWithTransmissionTargetToken:transmissionTargetToken
                         parentTarget:nil
                         channelGroup:self.channelGroup];
  MSLogDebug([MSAnalytics logTag], @"Created transmission target with id %@.",
             [MSUtility targetIdFromTargetToken:transmissionTargetToken]);
  [self.transmissionTargets setObject:transmissionTarget
                               forKey:transmissionTargetToken];

  // TODO: Start service if not already.
  // Scenario: getTransmissionTarget gets called before App Center has an app
  // secret or transmission target but start has been called for this service.
  return transmissionTarget;
}

+ (void)resetSharedInstance {

  // resets the once_token so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
}

#pragma mark - MSSessionTracker

- (void)sessionTracker:(id)sessionTracker processLog:(id<MSLog>)log {
  (void)sessionTracker;
  [self sendLog:log];
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
  if ([logObject isKindOfClass:[MSEventLog class]] &&
      [self.delegate
          respondsToSelector:@selector(analytics:willSendEventLog:)]) {
    MSEventLog *eventLog = (MSEventLog *)log;
    [self.delegate analytics:self willSendEventLog:eventLog];
  } else if ([logObject isKindOfClass:[MSPageLog class]] &&
             [self.delegate
                 respondsToSelector:@selector(analytics:willSendPageLog:)]) {
    MSPageLog *pageLog = (MSPageLog *)log;
    [self.delegate analytics:self willSendPageLog:pageLog];
  }
}

- (void)channel:(id<MSChannelProtocol>)channel
    didSucceedSendingLog:(id<MSLog>)log {
  (void)channel;
  if (!self.delegate) {
    return;
  }
  NSObject *logObject = (NSObject *)log;
  if ([logObject isKindOfClass:[MSEventLog class]] &&
      [self.delegate
          respondsToSelector:@selector(analytics:didSucceedSendingEventLog:)]) {
    MSEventLog *eventLog = (MSEventLog *)log;
    [self.delegate analytics:self didSucceedSendingEventLog:eventLog];
  } else if ([logObject isKindOfClass:[MSPageLog class]] &&
             [self.delegate respondsToSelector:@selector
                            (analytics:didSucceedSendingPageLog:)]) {
    MSPageLog *pageLog = (MSPageLog *)log;
    [self.delegate analytics:self didSucceedSendingPageLog:pageLog];
  }
}

- (void)channel:(id<MSChannelProtocol>)channel
    didFailSendingLog:(id<MSLog>)log
            withError:(NSError *)error {
  (void)channel;
  if (!self.delegate) {
    return;
  }
  NSObject *logObject = (NSObject *)log;
  if ([logObject isKindOfClass:[MSEventLog class]] &&
      [self.delegate respondsToSelector:@selector
                     (analytics:didFailSendingEventLog:withError:)]) {
    MSEventLog *eventLog = (MSEventLog *)log;
    [self.delegate analytics:self
        didFailSendingEventLog:eventLog
                     withError:error];
  } else if ([logObject isKindOfClass:[MSPageLog class]] &&
             [self.delegate respondsToSelector:@selector
                            (analytics:didFailSendingPageLog:withError:)]) {
    MSPageLog *pageLog = (MSPageLog *)log;
    [self.delegate analytics:self
        didFailSendingPageLog:pageLog
                    withError:error];
  }
}

#pragma mark Transmission Target

/**
 * Get a transmission target.
 *
 * @param transmissionTargetToken token of the transmission target to retrieve.
 *
 * @returns The transmissionTarget object.
 */
+ (MSAnalyticsTransmissionTarget *)transmissionTargetForToken:
    (NSString *)transmissionTargetToken {
  return [[MSAnalytics sharedInstance]
      transmissionTargetFor:transmissionTargetToken];
}

@end
