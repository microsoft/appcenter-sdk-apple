/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASessionTracker.h"
#import "AVAStartSessionLog.h"
#import "AvalancheHub+Internal.h"
#import <UIKit/UIKit.h>

static NSTimeInterval const kAVASessionTimeOut = 20;
static NSString *const kAVAPastSessionsKey = @"kAVAPastSessionsKey";
static NSString *const kAVALastEnteredBackgroundKey = @"kAVALastEnteredBackgroundKey";
static NSString *const kAVALastEnteredForegroundTime = @"kAVALastEnteredForegroundTime";
static NSUInteger const kAVAMaxSessionHistoryCount = 5;

@interface AVASessionTracker ()

/**
 * Current session id
 */
@property(nonatomic, readwrite) NSString *sessionId;

/**
 *  Flag to indicate if session tracking has started or not.
 */
@property(nonatomic) BOOL started;

/**
 *  Check if current session has timed out.
 *
 *  @return YES if current session has timed out, NO otherwise
 */
- (BOOL)hasSessionTimedOut;

@end

@implementation AVASessionTracker

- (instancetype)init {
  if (self = [super init]) {
    _sessionTimeout = kAVASessionTimeOut;

    // Restore past sessions from NSUserDefaults.
    NSData *sessions = [kAVAUserDefaults objectForKey:kAVAPastSessionsKey];
    if (sessions != nil) {
      NSArray *arrayFromData = [NSKeyedUnarchiver unarchiveObjectWithData:sessions];

      // If array is not nil, create a mutable version.
      if (arrayFromData)
        _pastSessions = [NSMutableArray arrayWithArray:arrayFromData];
    }

    // Create new array.
    if (_pastSessions == nil)
      _pastSessions = [NSMutableArray<AVASessionHistoryInfo *> new];

    // Session tracking is not started by default.
    _started = NO;
  }
  return self;
}

- (NSString *)sessionId {

  // Check if new session id is required.
  if (_sessionId == nil || [self hasSessionTimedOut]) {
    _sessionId = kAVAUUIDString;

    // Record session.
    AVASessionHistoryInfo *sessionInfo = [[AVASessionHistoryInfo alloc] init];
    sessionInfo.sessionId = _sessionId;
    sessionInfo.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

    // Insert at the beginning of the list.
    [self.pastSessions insertObject:sessionInfo atIndex:0];

    // Remove last item if reached max limit.
    if ([self.pastSessions count] > kAVAMaxSessionHistoryCount)
      [self.pastSessions removeLastObject];

    // Persist the session history in NSData format.
    [kAVAUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.pastSessions] forKey:kAVAPastSessionsKey];
    [kAVAUserDefaults synchronize];
    AVALogVerbose(@"INFO:new session ID: %@", _sessionId);

    // Create a start session log.
    AVAStartSessionLog *log = [[AVAStartSessionLog alloc] init];
    log.sid = _sessionId;
    [self.delegate sessionTracker:self processLog:log withPriority:AVAPriorityDefault];
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

  @synchronized(self) {
    NSDate *now = [NSDate date];

    // Verify if last time that a log was sent is longer than the session timeout time.
    BOOL noLogSentForLong = [now timeIntervalSinceDate:self.lastCreatedLogTime] >= self.sessionTimeout;

    // Verify if app is currently in the background for a longer time than the
    BOOL isBackgroundForLong =
        (self.lastEnteredBackgroundTime && self.lastEnteredForegroundTime) &&
        ([self.lastEnteredBackgroundTime compare:self.lastEnteredForegroundTime] == NSOrderedDescending) &&
        ([now timeIntervalSinceDate:self.lastEnteredBackgroundTime] >= self.sessionTimeout);

    // Verify if app was in the background for a longer time than the session
    // timeout time.
    BOOL wasBackgroundForLong = (self.lastEnteredBackgroundTime)
                                    ? [self.lastEnteredForegroundTime
                                          timeIntervalSinceDate:self.lastEnteredBackgroundTime] >= self.sessionTimeout
                                    : false;
    return noLogSentForLong && (isBackgroundForLong || wasBackgroundForLong);
  }
}

- (void)applicationDidEnterBackground {
  self.lastEnteredBackgroundTime = [NSDate date];
}

- (void)applicationWillEnterForeground {
  self.lastEnteredForegroundTime = [NSDate date];
}

#pragma mark - AVALogManagerListener

- (void)onProcessingLog:(id<AVALog>)log withPriority:(AVAPriority)priority {

  // Start session log is created in this method, therefore, skip in order to avoid infinite loop.
  if ([((NSObject *)log) isKindOfClass:[AVAStartSessionLog class]])
    return;

  if (log.toffset != nil) {
    [self.pastSessions
        enumerateObjectsUsingBlock:^(AVASessionHistoryInfo *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
          if ([log.toffset compare:obj.toffset] == NSOrderedDescending) {
            log.sid = obj.sessionId;
            *stop = YES;
          }
        }];
  }

  // If log is not correlated to a past session.
  if (log.sid == nil) {
    log.sid = self.sessionId;
  }

  // Update time stamp.
  _lastCreatedLogTime = [NSDate date];
}

@end