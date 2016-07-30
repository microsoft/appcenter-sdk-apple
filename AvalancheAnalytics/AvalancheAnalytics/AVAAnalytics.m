/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAnalyticsPrivate.h"
#import "AvalancheHub+Internal.h"
#import "AVAEventLog.h"
#import "AVAPageLog.h"
#import "AVAAnalyticsCategory.h"

@implementation AVAAnalytics

@synthesize delegate = _delegate;
@synthesize isEnabled = _isEnabled;
@synthesize autoPageTrackingEnabled = _autoPageTrackingEnabled;

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
    _isEnabled = YES;
    _autoPageTrackingEnabled = YES;
  }
  return self;
}

- (void)startFeature {
  // Enabled auto page tracking
  if (self.autoPageTrackingEnabled) {
    [AVAAnalyticsCategory activateCategory];
  }
  AVALogVerbose(@"AVAAnalytics: Started analytics module");
}

- (void)setDelegate:(id<AVAAvalancheDelegate>) delegate {
  _delegate = delegate;
}

+ (void)setEnable:(BOOL)isEnabled {
  [[self sharedInstance] setEnable:isEnabled];
}

+ (BOOL)isEnabled {
  return [[self sharedInstance] isEnabled];
}

+ (void)trackEvent:(NSString*)eventName withProperties:(NSDictionary *)properties {
   [[self sharedInstance] trackEvent:eventName withProperties:properties];
}

+ (void)trackPage:(NSString*)pageName withProperties:(NSDictionary *)properties {
  [[self sharedInstance] trackPage:pageName withProperties:properties];
}

+ (void)setAutoPageTrackingEnabled:(BOOL)isEnabled {
  [[self sharedInstance] setAutoPageTrackingEnabled:isEnabled];
}

+ (BOOL)isAutoPageTrackingEnabled {
  return [[self sharedInstance] isAutoPageTrackingEnabled];
}

#pragma mark - private methods

- (void)trackEvent:(NSString*)eventName withProperties:(NSDictionary *)properties {
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
    [self.delegate feature:self didCreateLog:log withPriority:AVAPriorityDefault];
  });
}

- (void)trackPage:(NSString*)pageName withProperties:(NSDictionary *)properties {
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
    [self.delegate feature:self didCreateLog:log withPriority:AVAPriorityDefault];
  });
}

- (void)setEnable:(BOOL)isEnabled {
  _isEnabled = isEnabled;
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

@end
