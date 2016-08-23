/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAnalyticsCategory.h"
#import "AVAAnalyticsPrivate.h"
#import "AVAAvalanche.h"
#import "AVAEventLog.h"
#import "AVAPageLog.h"
#import "AvalancheHub+Internal.h"
#import "Internals/AVAAvalanchePrivate.h"

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

#pragma mark - AVAFeature

+ (void)setEnabled:(BOOL)isEnabled {
  if ([AVAAvalanche sharedInstance].featuresStarted) {
    [[self sharedInstance] setEnabled:isEnabled];
  } else {
    [[self sharedInstance] logSDKNotInitializedError];
  }
}

+ (BOOL)isEnabled {
  if ([AVAAvalanche sharedInstance].featuresStarted) {
    return [[self sharedInstance] isEnabled];
  } else {
    [[self sharedInstance] logSDKNotInitializedError];
    return NO;
  }
}

- (void)logSDKNotInitializedError {
  AVALogError(@"[AVAAnalytics] ERROR: SonomaSDK hasn't been initialized. You need to call [AVAAvalanche "
              @"start:YOUR_APP_SECRET withFeatures:LIST_OF_FEATURES] first.");
  ;
}

#pragma mark - Other Public Methods

+ (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary *)properties {
  if ([AVAAvalanche sharedInstance].featuresStarted) {
    [[self sharedInstance] trackEvent:eventName withProperties:properties];
  } else {
    [[self sharedInstance] logSDKNotInitializedError];
  }
}

+ (void)trackPage:(NSString *)pageName withProperties:(NSDictionary *)properties {
  if ([AVAAvalanche sharedInstance].featuresStarted) {

    [[self sharedInstance] trackPage:pageName withProperties:properties];
  } else {
    [[self sharedInstance] logSDKNotInitializedError];
  }
}

+ (void)setAutoPageTrackingEnabled:(BOOL)isEnabled {
  if ([AVAAvalanche sharedInstance].featuresStarted) {

    [[self sharedInstance] setAutoPageTrackingEnabled:isEnabled];
  } else {
    [[self sharedInstance] logSDKNotInitializedError];
  }
}

+ (BOOL)isAutoPageTrackingEnabled {
  if ([AVAAvalanche sharedInstance].featuresStarted) {
    return [[self sharedInstance] isAutoPageTrackingEnabled];
  } else {
    [[self sharedInstance] logSDKNotInitializedError];
    return NO;
  }
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
