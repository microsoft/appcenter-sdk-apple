/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMAnalytics.h"
#import "SNMAnalyticsCategory.h"
#import "SNMAnalyticsPrivate.h"
#import "SNMEventLog.h"
#import "MSFeatureAbstractProtected.h"
#import "MSLogManager.h"
#import "SNMPageLog.h"

/**
 *  Feature storage key name.
 */
static NSString *const kSNMFeatureName = @"Analytics";

@implementation SNMAnalytics

@synthesize autoPageTrackingEnabled = _autoPageTrackingEnabled;

#pragma mark - Module initialization

- (instancetype)init {
  if (self = [super init]) {

    // Set defaults.
    _autoPageTrackingEnabled = YES;

    // Init session tracker.
    _sessionTracker = [[SNMSessionTracker alloc] init];
    _sessionTracker.delegate = self;
  }
  return self;
}

#pragma mark - SNMFeatureInternal

+ (instancetype)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)startWithLogManager:(id<MSLogManager>)logManager {
  [super startWithLogManager:logManager];

  // Set up swizzling for auto page tracking.
  [SNMAnalyticsCategory activateCategory];
  MSLogVerbose([SNMAnalytics getLoggerTag], @"Started analytics module");
}

+ (NSString *)getLoggerTag {
  return @"SonomaAnalytics";
}

- (NSString *)storageKey {
  return kSNMFeatureName;
}

- (MSPriority)priority {
  return MSPriorityDefault;
}

#pragma mark - SNMFeatureAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {

    // Start session tracker.
    [self.sessionTracker start];

    // Add delegate to log manager.
    [self.logManager addDelegate:self.sessionTracker];

    // Report current page while auto page traking is on.
    if (self.autoPageTrackingEnabled) {

      // Track on the main queue to avoid race condition with page swizzling.
      dispatch_async(dispatch_get_main_queue(), ^{
        if ([[SNMAnalyticsCategory missedPageViewName] length] > 0) {
          [[self class] trackPage:[SNMAnalyticsCategory missedPageViewName]];
        }
      });
    }
  } else {
    [self.logManager removeDelegate:self.sessionTracker];
    [self.sessionTracker stop];
    [self.sessionTracker clearSessions];
  }
}

#pragma mark - Module methods

+ (void)trackEvent:(NSString *)eventName {
  [self trackEvent:eventName withProperties:nil];
}

+ (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary *)properties {
  @synchronized(self) {
    if ([[self sharedInstance] canBeUsed]) {
      [[self sharedInstance] trackEvent:eventName withProperties:properties];
    }
  }
}

+ (void)trackPage:(NSString *)pageName {
  [self trackPage:pageName withProperties:nil];
}

+ (void)trackPage:(NSString *)pageName withProperties:(NSDictionary *)properties {
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

- (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary *)properties {
  if (![self isEnabled])
    return;

  // Create and set properties of the event log
  SNMEventLog *log = [[SNMEventLog alloc] init];
  log.name = eventName;
  log.eventId = kSNMUUIDString;
  if (properties)
    log.properties = properties;

  // Send log to core module
  [self sendLog:log withPriority:self.priority];
}

- (void)trackPage:(NSString *)pageName withProperties:(NSDictionary *)properties {
  if (![super isEnabled])
    return;

  // Create and set properties of the event log
  SNMPageLog *log = [[SNMPageLog alloc] init];
  log.name = pageName;
  if (properties)
    log.properties = properties;

  // Send log to core module
  [self sendLog:log withPriority:self.priority];
}

- (void)setAutoPageTrackingEnabled:(BOOL)isEnabled {
  _autoPageTrackingEnabled = isEnabled;
}

- (BOOL)isAutoPageTrackingEnabled {
  return _autoPageTrackingEnabled;
}

- (void)sendLog:(id<MSLog>)log withPriority:(MSPriority)priority {

  // Send log to core module.
  [self.logManager processLog:log withPriority:priority];
}

#pragma mark - SNMSessionTracker

- (void)sessionTracker:(id)sessionTracker processLog:(id<MSLog>)log withPriority:(MSPriority)priority {
  [self sendLog:log withPriority:priority];
}

@end
