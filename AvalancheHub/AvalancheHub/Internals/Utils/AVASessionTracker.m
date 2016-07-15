/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASessionTracker.h"
#import "AVASettings.h"
#import "AVAUtils.h"
#import "AvalancheHub+Internal.h"
#import <UIKit/UIKit.h>

static NSTimeInterval const kAVASessionTimeOut = 20;
static NSString *const kAVALastEnteredBackgroundKey =
    @"kAVALastEnteredBackgroundKey";
static NSString *const kAVALastEnteredForegroundTime =
    @"kAVALastEnteredForegroundTime";

@interface AVASessionTracker ()

/**
 * Current session id
 */
@property(nonatomic) NSString *sid;

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

- (instancetype)initWithChannel:(id<AVAChannel>)channel {
  if (self = [super init]) {
    _channel = channel;
    _sessionTimeout = kAVASessionTimeOut;
    
    // Session tracking is not started by default
    _started = NO;

    // TODO: restore persisted values
  }
  return self;
}

- (NSString *)getSessionId {

  // Check if new session id is required
  if (self.sid == nil || [self hasSessionTimedOut]) {
    _sid = kAVAUUIDString;

    // Call the delegate with the new session id
    [self.delegate sessionTracker:self didRenewSessionWithId:self.sid];
    AVALogVerbose(@"INFO:new session ID: %@", self.sid);
  }
  return self.sid;
}

- (void)start {
  if (!_started) {
    [kAVANotificationCenter addObserver:self selector:@selector(applicationDidEnterBackground)
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
  NSDate *lastQueuedLogTime = [self.channel lastQueuedLogTime];

  BOOL noLogSentForLong =
      [now timeIntervalSinceDate:lastQueuedLogTime] >= self.sessionTimeout;
  BOOL isBackgroundForLong =
      self.lastEnteredBackgroundTime >= self.lastEnteredForegroundTime &&
      [now timeIntervalSinceDate:self.lastEnteredBackgroundTime] >=
          self.sessionTimeout;
  BOOL wasBackgroundForLong =
      [self.lastEnteredForegroundTime
          timeIntervalSinceDate:self.lastEnteredBackgroundTime] >=
      self.sessionTimeout;
  return noLogSentForLong && (isBackgroundForLong || wasBackgroundForLong);
}

- (void)applicationDidEnterBackground {
  self.lastEnteredBackgroundTime = [NSDate date];

  // TODO Persist the time
  // [kAVASettings setObject:self.lastEnteredBackgroundTime
  // forKey:kAVALastEnteredBackgroundKey];
}

- (void)applicationWillEnterForeground {
  self.lastEnteredForegroundTime = [NSDate date];

  // TODO Persist the time
  // [kAVASettings lastEnteredForegroundTime
  // forKey:kAVALastEnteredForegroundKey];
}

- (AVADeviceLog *)getDeviceLog {
  // TODO use util function
  AVADeviceLog *device = [[AVADeviceLog alloc] init];

  return device;
}

@end