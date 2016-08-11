/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAnalyticsCategory.h"
#import "AVAAnalyticsPrivate.h"
#import "AVAEventLog.h"
#import "AVAPageLog.h"
#import "AvalancheHub+Internal.h"

@implementation AVAAnalytics

@synthesize delegate = _delegate;
@synthesize isEnabled = _isEnabled;
@synthesize autoPageTrackingEnabled = _autoPageTrackingEnabled;
@synthesize logManger = _logManger;

+ (id)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (id)init {
  if (self = [super init]) {

    // Set defaults.
    _isEnabled = YES;
    _autoPageTrackingEnabled = YES;

    // Init session tracker.
    _sessionTracker = [[AVASessionTracker alloc] init];
    _sessionTracker.delegate = self;
    [self.sessionTracker start];
  }
  return self;
}

- (void)startFeature {
  
  // Add listener to log manager.
  [self.logManger addListener:_sessionTracker];

  // Enabled auto page tracking
  if (self.autoPageTrackingEnabled) {
    [AVAAnalyticsCategory activateCategory];
  }
  AVALogVerbose(@"AVAAnalytics: Started analytics module");
}

- (void)setDelegate:(id<AVAAvalancheDelegate>)delegate {
  _delegate = delegate;
}

+ (void)setEnabled:(BOOL)isEnabled {
  [[self sharedInstance] setEnabled:isEnabled];
}

+ (BOOL)isEnabled {
  return [[self sharedInstance] isEnabled];
}

+ (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary *)properties {
  [[self sharedInstance] trackEvent:eventName withProperties:properties];
}

+ (void)trackPage:(NSString *)pageName withProperties:(NSDictionary *)properties {
  [[self sharedInstance] trackPage:pageName withProperties:properties];
}

+ (void)setAutoPageTrackingEnabled:(BOOL)isEnabled {
  [[self sharedInstance] setAutoPageTrackingEnabled:isEnabled];
}

+ (BOOL)isAutoPageTrackingEnabled {
  return [[self sharedInstance] isAutoPageTrackingEnabled];
}

#pragma mark - private methods

- (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary *)properties {
  if (![self isEnabled])
    return;

  // Send async
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    // Create and set properties of the event log
    AVAEventLog *log = [[AVAEventLog alloc] init];
    log.name = eventName;
    log.eventId = kAVAUUIDString;
    if (properties)
      log.properties = properties;

    // Send log to core module
    [self sendLog:log withPriority:AVAPriorityDefault];
  });
}

- (void)trackPage:(NSString *)pageName withProperties:(NSDictionary *)properties {
  if (![self isEnabled])
    return;

  // Send async
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    // Create and set properties of the event log
    AVAPageLog *log = [[AVAPageLog alloc] init];
    log.name = pageName;
    if (properties)
      log.properties = properties;

    // Send log to core module
    [self sendLog:log withPriority:AVAPriorityDefault];
  });
}

- (void)setEnabled:(BOOL)isEnabled {
  _isEnabled = isEnabled;
  isEnabled ? [self.logManger addListener:self.sessionTracker] : [self.logManger removeListener:self.sessionTracker];
}

- (BOOL)isEnabled {
  return _isEnabled;
}

- (void)setAutoPageTrackingEnabled:(BOOL)isEnabled {
  _autoPageTrackingEnabled = isEnabled;
}

- (BOOL)isAutoPageTrackingEnabled {
  return _autoPageTrackingEnabled;
}

- (void)sendLog:(id<AVALog>)log withPriority:(AVAPriority)priority {
  // Send log to core module.
  [self.logManger processLog:log withPriority:priority];
}

- (void)sessionTracker:(id)sessionTracker processLog:(id<AVALog>)log withPriority:(AVAPriority)priority {
  [self sendLog:log withPriority:priority];
}

- (void)onLogManagerReady:(id<AVALogManager>)logManger {
  _logManger = logManger;
}

@end
