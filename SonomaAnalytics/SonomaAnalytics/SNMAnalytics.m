/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMAnalytics.h"
#import "SNMAnalyticsCategory.h"
#import "SNMAnalyticsPrivate.h"
#import "SNMSonoma.h"
#import "SNMSonomaInternal.h"

#import "SNMEventLog.h"
#import "SNMPageLog.h"
#import "SonomaCore+Internal.h"

/**
 *  Feature name.
 */
static NSString *const kSNMFeatureName = @"Analytics";

@implementation SNMAnalytics

@synthesize autoPageTrackingEnabled = _autoPageTrackingEnabled;
@synthesize priority = _priority;


#pragma mark - Module initialization

- (instancetype)init {
  if (self = [super init]) {

    // Set defaults.
    _autoPageTrackingEnabled = YES;

    // Init session tracker.
    _sessionTracker = [[SNMSessionTracker alloc] init];
    _sessionTracker.delegate = self;
    _priority = SNMPriorityDefault;
    [self.sessionTracker start];
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

- (void)startFeature {
  [super startFeature];
  
  // Add listener to log manager.
  [self.logManger addListener:_sessionTracker];

  // Enabled auto page tracking
  if (self.autoPageTrackingEnabled) {
    [SNMAnalyticsCategory activateCategory];
  }
  SNMLogVerbose(@"SNMAnalytics: Started analytics module");
}

- (NSString *)featureName {
  return kSNMFeatureName;
}

#pragma mark - SNMFeatureAbstract

- (void)setEnabled:(BOOL)isEnabled {
  if ([self canBeUsed]) {
    isEnabled ? [self.logManger addListener:self.sessionTracker] : [self.logManger removeListener:self.sessionTracker];
    [super setEnabled:isEnabled];
  }
}

#pragma mark - Module methods

+ (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary *)properties {
  if ([[self sharedInstance] canBeUsed]) {
    [[self sharedInstance] trackEvent:eventName withProperties:properties];
  }
}

+ (void)trackPage:(NSString *)pageName withProperties:(NSDictionary *)properties {
  if ([[self sharedInstance] canBeUsed]) {
    [[self sharedInstance] trackPage:pageName withProperties:properties];
  }
}

+ (void)setAutoPageTrackingEnabled:(BOOL)isEnabled {
  if ([[self sharedInstance] canBeUsed]) {
    [[self sharedInstance] setAutoPageTrackingEnabled:isEnabled];
  }
}

+ (BOOL)isAutoPageTrackingEnabled {
  if ([[self sharedInstance] canBeUsed]) {
    return [[self sharedInstance] isAutoPageTrackingEnabled];
  } else {
    return NO;
  }
}

#pragma mark - Private methods

- (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary *)properties {
  if (![self isEnabled])
    return;

  // Send async
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    // Create and set properties of the event log
    SNMEventLog *log = [[SNMEventLog alloc] init];
    log.name = eventName;
    log.eventId = kSNMUUIDString;
    if (properties)
      log.properties = properties;

    // Send log to core module
    [self sendLog:log withPriority:self.priority];
  });
}

- (void)trackPage:(NSString *)pageName withProperties:(NSDictionary *)properties {
  if (![super isEnabled])
    return;

  // Send async
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    // Create and set properties of the event log
    SNMPageLog *log = [[SNMPageLog alloc] init];
    log.name = pageName;
    if (properties)
      log.properties = properties;

    // Send log to core module
    [self sendLog:log withPriority:self.priority];
  });
}

- (void)setAutoPageTrackingEnabled:(BOOL)isEnabled {
  _autoPageTrackingEnabled = isEnabled;
}

- (BOOL)isAutoPageTrackingEnabled {
  return _autoPageTrackingEnabled;
}

- (void)sendLog:(id<SNMLog>)log withPriority:(SNMPriority)priority {

  // Send log to core module.
  [self.logManger processLog:log withPriority:priority];
}

#pragma mark - SNMSessionTracker

- (void)sessionTracker:(id)sessionTracker processLog:(id<SNMLog>)log withPriority:(SNMPriority)priority {
  [self sendLog:log withPriority:priority];
}

@end
