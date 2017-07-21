#import "MSAnalytics.h"
#import "MSAnalyticsCategory.h"
#import "MSAnalyticsInternal.h"
#import "MSAnalyticsPrivate.h"
#import "MSEventLog.h"
#import "MSPageLog.h"
#import "MSServiceAbstractProtected.h"

// Service name for initialization.
static NSString *const kMSServiceName = @"Analytics";

// The group Id for storage.
static NSString *const kMSGroupId = @"Analytics";

// Singleton
static MSAnalytics *sharedInstance = nil;
static dispatch_once_t onceToken;

// Events values limitations
static const int minEventNameLength = 1;
static const int maxEventNameLength = 256;
static const int maxPropertiesPerEvent = 5;
static const int minPropertyKeyLength = 1;
static const int maxPropertyKeyLength = 64;
static const int maxPropertyValueLength = 64;

@implementation MSAnalytics

@synthesize autoPageTrackingEnabled = _autoPageTrackingEnabled;
@synthesize channelConfiguration = _channelConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {

    // Set defaults.
    _autoPageTrackingEnabled = NO;

    // Init session tracker.
    _sessionTracker = [[MSSessionTracker alloc] init];
    _sessionTracker.delegate = self;

    // Init channel configuration.
    _channelConfiguration = [[MSChannelConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];
  }
  return self;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[self alloc] init];
    }
  });
  return sharedInstance;
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];

  // Set up swizzling for auto page tracking.
  [MSAnalyticsCategory activateCategory];
  MSLogVerbose([MSAnalytics logTag], @"Started Analytics service.");
}

+ (NSString *)logTag {
  return @"MobileCenterAnalytics";
}

- (NSString *)groupId {
  return kMSGroupId;
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {

    // Start session tracker.
    [self.sessionTracker start];

    // Add delegates to log manager.
    [self.logManager addDelegate:self.sessionTracker];
    [self.logManager addDelegate:self];

    // Report current page while auto page tracking is on.
    if (self.autoPageTrackingEnabled) {

      // Track on the main queue to avoid race condition with page swizzling.
      dispatch_async(dispatch_get_main_queue(), ^{
        if ([[MSAnalyticsCategory missedPageViewName] length] > 0) {
          [[self class] trackPage:(NSString * _Nonnull)[MSAnalyticsCategory missedPageViewName]];
        }
      });
    }

    MSLogInfo([MSAnalytics logTag], @"Analytics service has been enabled.");
  } else {
    [self.logManager removeDelegate:self.sessionTracker];
    [self.logManager removeDelegate:self];
    [self.sessionTracker stop];
    [self.sessionTracker clearSessions];
    MSLogInfo([MSAnalytics logTag], @"Analytics service has been disabled.");
  }
}

#pragma mark - Service methods

+ (void)trackEvent:(NSString *)eventName {
  [self trackEvent:eventName withProperties:nil];
}

+ (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  @synchronized(self) {
    if ([[self sharedInstance] canBeUsed]) {
      [[self sharedInstance] trackEvent:eventName withProperties:properties];
    }
  }
}

+ (void)trackPage:(NSString *)pageName {
  [self trackPage:pageName withProperties:nil];
}

+ (void)trackPage:(NSString *)pageName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  @synchronized(self) {
    if ([[self sharedInstance] canBeUsed]) {
      [[self sharedInstance] trackPage:pageName withProperties:properties];
    }
  }
}

+ (void)setAutoPageTrackingEnabled:(BOOL)isEnabled {
  @synchronized(self) {
    [[self sharedInstance] setAutoPageTrackingEnabled:isEnabled];
  }
}

+ (BOOL)isAutoPageTrackingEnabled {
  @synchronized(self) {
    return [[self sharedInstance] isAutoPageTrackingEnabled];
  }
}

#pragma mark - Private methods

- (BOOL)validateEventName:(NSString *)eventName forLogType:(NSString *)logType {
  if (!eventName || [eventName length] < minEventNameLength) {
    MSLogError([MSAnalytics logTag],
               @"%@ name cannot be null or empty", logType);
    return NO;
  }
  if ([eventName length] > maxEventNameLength) {
    MSLogError([MSAnalytics logTag],
               @"%@ '%@' : name length cannot be longer than %d characters", logType, eventName, maxEventNameLength);
    return NO;
  }
  return YES;
}

- (NSDictionary<NSString *, NSString *> *)validateProperties:(NSDictionary<NSString *, NSString *> *)properties
                                                  forLogName:(NSString *)logName
                                                     andType:(NSString *)logType {
  NSMutableDictionary<NSString *, NSString *> *validProperties = [NSMutableDictionary new];
  for (id key in properties) {

    // Don't send more properties than we can.
    if ([validProperties count] >= maxPropertiesPerEvent) {
      MSLogWarning([MSAnalytics logTag],
                   @"%@ '%@' : properties cannot contain more than %d items. Skipping other properties.",
                   logType,
                   logName,
                   maxPropertiesPerEvent);
      break;
    }
    if (![key isKindOfClass:[NSString class]] || ![properties[key] isKindOfClass:[NSString class]]) {
      continue;
    }

    // Validate key.
    NSString *strKey = key;
    if ([strKey length] < minPropertyKeyLength) {
      MSLogWarning([MSAnalytics logTag],
                   @"%@ '%@' : a property key cannot be null or empty. Property will be skipped.",
                   logType,
                   logName);
      continue;
    }
    if ([strKey length] > maxPropertyKeyLength) {
      MSLogWarning([MSAnalytics logTag],
                   @"%@ '%@' : property %@ : property key length cannot be longer than %d characters. Property %@ will be skipped.",
                   logType,
                   logName,
                   strKey,
                   maxPropertyKeyLength,
                   strKey);
      continue;
    }

    // Validate value.
    NSString *value = properties[key];
    if([value length] > maxPropertyValueLength) {
      MSLogWarning([MSAnalytics logTag],
                   @"%@ '%@' : property '%@' : property value cannot be longer than %d characters. Property %@ will be skipped.",
                   logType,
                   logName,
                   strKey,
                   maxPropertyValueLength,
                   strKey);
      continue;
    }

    // Save valid properties.
    [validProperties setObject:value forKey:key];
  }
  return validProperties;
}

- (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary<NSString *, NSString *> *)properties {
  if (![self isEnabled])
    return;

  // Create an event log.
  MSEventLog *log = [MSEventLog new];

  // Validate event name.
  if (![self validateEventName:eventName forLogType:log.type]) {
    return;
  }

  // Set properties of the event log.
  log.name = eventName;
  log.eventId = MS_UUID_STRING;
  if (properties && properties.count > 0) {

    // Send only valid properties.
    log.properties = [self validateProperties:properties forLogName:log.name andType:log.type];
  }

  // Send log to log manager.
  [self sendLog:log];
}

- (void)trackPage:(NSString *)pageName withProperties:(NSDictionary<NSString *, NSString *> *)properties {
  if (![super isEnabled])
    return;

  // Create an event log.
  MSPageLog *log = [MSPageLog new];

  // Validate event name.
  if (![self validateEventName:pageName forLogType:log.type]) {
    return;
  }

  // Set properties of the event log.
  log.name = pageName;
  if (properties && properties.count > 0) {

    // Send only valid properties.
    log.properties = [self validateProperties:properties forLogName:log.name andType:log.type];
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
  [self.logManager processLog:log forGroupId:self.groupId];
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
  [[self sharedInstance] setDelegate:delegate];
}

#pragma mark - MSLogManagerDelegate

- (void)willSendLog:(id<MSLog>)log {
  if (!self.delegate) {
    return;
  }
  NSObject *logObject = (NSObject *)log;
  if ([logObject isKindOfClass:[MSEventLog class]] &&
      [self.delegate respondsToSelector:@selector(analytics:willSendEventLog:)]) {
    MSEventLog *eventLog = (MSEventLog *)log;
    [self.delegate analytics:self willSendEventLog:eventLog];
  } else if ([logObject isKindOfClass:[MSPageLog class]] &&
             [self.delegate respondsToSelector:@selector(analytics:willSendPageLog:)]) {
    MSPageLog *pageLog = (MSPageLog *)log;
    [self.delegate analytics:self willSendPageLog:pageLog];
  }
}

- (void)didSucceedSendingLog:(id<MSLog>)log {
  if (!self.delegate) {
    return;
  }
  NSObject *logObject = (NSObject *)log;
  if ([logObject isKindOfClass:[MSEventLog class]] &&
      [self.delegate respondsToSelector:@selector(analytics:didSucceedSendingEventLog:)]) {
    MSEventLog *eventLog = (MSEventLog *)log;
    [self.delegate analytics:self didSucceedSendingEventLog:eventLog];
  } else if ([logObject isKindOfClass:[MSPageLog class]] &&
             [self.delegate respondsToSelector:@selector(analytics:didSucceedSendingPageLog:)]) {
    MSPageLog *pageLog = (MSPageLog *)log;
    [self.delegate analytics:self didSucceedSendingPageLog:pageLog];
  }
}

- (void)didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  if (!self.delegate) {
    return;
  }
  NSObject *logObject = (NSObject *)log;
  if ([logObject isKindOfClass:[MSEventLog class]] &&
      [self.delegate respondsToSelector:@selector(analytics:didFailSendingEventLog:withError:)]) {
    MSEventLog *eventLog = (MSEventLog *)log;
    [self.delegate analytics:self didFailSendingEventLog:eventLog withError:error];
  } else if ([logObject isKindOfClass:[MSPageLog class]] &&
             [self.delegate respondsToSelector:@selector(analytics:didFailSendingPageLog:withError:)]) {
    MSPageLog *pageLog = (MSPageLog *)log;
    [self.delegate analytics:self didFailSendingPageLog:pageLog withError:error];
  }
}

@end
