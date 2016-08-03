/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASessionTracker.h"
#import "AvalancheHub+Internal.h"
#import <UIKit/UIKit.h>

static NSTimeInterval const kAVASessionTimeOut = 20;
static NSString *const kAVASessionIdKey = @"kAVASessionId";
static NSString *const kAVALastEnteredBackgroundKey = @"kAVALastEnteredBackgroundKey";
static NSString *const kAVALastEnteredForegroundTime = @"kAVALastEnteredForegroundTime";

@interface AVASessionTracker ()

/**
 * Current session id
 */
@property(nonatomic, readwrite) NSString *sessionId;

/**
 *  Flag to indicate if session tracking has started or not
 */
@property(nonatomic) BOOL started;

/**
 *  Check if current session has timed out
 *
 *  @return YES if current session has timed out, NO otherwise
 */
- (BOOL)hasSessionTimedOut;

@end

@implementation AVASessionTracker

- (instancetype)init {
  if (self = [super init]) {
    _sessionTimeout = kAVASessionTimeOut;

    // Session tracking is not started by default
    _started = NO;
  }
  return self;
}

- (NSString *)sessionId {

  // Check if new session id is required
  if (_sessionId == nil || [self hasSessionTimedOut]) {
    _sessionId = kAVAUUIDString;

    // Persist the session id
    [kAVASettings setObject:_sessionId forKey:kAVASessionIdKey];
    [kAVASettings synchronize];

    // Call the delegate with the new session id
    [self.delegate sessionTracker:self didRenewSessionWithId:_sessionId];
    AVALogVerbose(@"INFO:new session ID: %@", _sessionId);
  }
  return _sessionId;
}

- (void)start {
  if (!_started) {
    [kAVANotificationCenter addObserver:self
                               selector:@selector(applicationDidEnterBackground)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
    [kAVANotificationCenter addObserver:self
                               selector:@selector(applicationWillEnterForeground)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
    _started = YES;
  }
}

- (void)stop {
  if (_started) {
    [kAVANotificationCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [kAVANotificationCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
  }
  _started = NO;
}

#pragma mark - private methods

- (BOOL)hasSessionTimedOut {
  NSDate *now = [NSDate date];

  // Verify if last time that a log was sent is longer than the session timeout time
  BOOL noLogSentForLong = [now timeIntervalSinceDate:self.lastCreatedLogTime] >= self.sessionTimeout;

  // Verify if app is currently in the background for a longer time than the
  BOOL isBackgroundForLong =
      (self.lastEnteredBackgroundTime && self.lastEnteredForegroundTime) &&
      ([self.lastEnteredBackgroundTime compare:self.lastEnteredForegroundTime] == NSOrderedDescending) &&
      ([now timeIntervalSinceDate:self.lastEnteredBackgroundTime] >= self.sessionTimeout);

  // Verify if app was in the background for a longer time than the session
  // timeout time
  BOOL wasBackgroundForLong =
      (self.lastEnteredBackgroundTime)
          ? [self.lastEnteredForegroundTime timeIntervalSinceDate:self.lastEnteredBackgroundTime] >= self.sessionTimeout
          : false;
  return noLogSentForLong && (isBackgroundForLong || wasBackgroundForLong);
}

- (void)applicationDidEnterBackground {
  self.lastEnteredBackgroundTime = [NSDate date];
}

- (void)applicationWillEnterForeground {
  self.lastEnteredForegroundTime = [NSDate date];
}

@end