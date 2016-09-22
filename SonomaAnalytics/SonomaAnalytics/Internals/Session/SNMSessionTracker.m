/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMSessionTracker.h"
#import "SNMStartSessionLog.h"
#import "SonomaCore+Internal.h"
#import <UIKit/UIKit.h>

static NSTimeInterval const kSNMSessionTimeOut = 20;
static NSString *const kSNMPastSessionsKey = @"kSNMPastSessionsKey";
static NSString *const kSNMLastEnteredBackgroundKey = @"kSNMLastEnteredBackgroundKey";
static NSString *const kSNMLastEnteredForegroundTime = @"kSNMLastEnteredForegroundTime";
static NSUInteger const kSNMMaxSessionHistoryCount = 5;

@interface SNMSessionTracker ()

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

@implementation SNMSessionTracker

- (instancetype)init {
  if (self = [super init]) {
    _sessionTimeout = kSNMSessionTimeOut;

    // Restore past sessions from NSUserDefaults.
    NSData *sessions = [kSNMUserDefaults objectForKey:kSNMPastSessionsKey];
    if (sessions != nil) {
      NSArray *arrayFromData = [NSKeyedUnarchiver unarchiveObjectWithData:sessions];

      // If array is not nil, create a mutable version.
      if (arrayFromData)
        _pastSessions = [NSMutableArray arrayWithArray:arrayFromData];
    }

    // Create new array.
    if (_pastSessions == nil)
      _pastSessions = [NSMutableArray<SNMSessionHistoryInfo *> new];

    // Session tracking is not started by default.
    _started = NO;
  }
  return self;
}

- (NSString *)sessionId {

  // Check if new session id is required.
  if (_sessionId == nil || [self hasSessionTimedOut]) {
    _sessionId = kSNMUUIDString;

    // Record session.
    SNMSessionHistoryInfo *sessionInfo = [[SNMSessionHistoryInfo alloc] init];
    sessionInfo.sessionId = _sessionId;
    sessionInfo.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

    // Insert at the beginning of the list.
    [self.pastSessions insertObject:sessionInfo atIndex:0];

    // Remove last item if reached max limit.
    if ([self.pastSessions count] > kSNMMaxSessionHistoryCount)
      [self.pastSessions removeLastObject];

    // Persist the session history in NSData format.
    [kSNMUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.pastSessions] forKey:kSNMPastSessionsKey];
    SNMLogVerbose(@"INFO:new session ID: %@", _sessionId);

    // Create a start session log.
    SNMStartSessionLog *log = [[SNMStartSessionLog alloc] init];
    log.sid = _sessionId;
    [self.delegate sessionTracker:self processLog:log withPriority:SNMPriorityDefault];
  }
  return _sessionId;
}

- (void)start {
  if (!_started) {
    [kSNMNotificationCenter addObserver:self
                               selector:@selector(applicationDidEnterBackground)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
    [kSNMNotificationCenter addObserver:self
                               selector:@selector(applicationWillEnterForeground)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
    _started = YES;
  }
}

- (void)stop {
  if (_started) {
    [kSNMNotificationCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [kSNMNotificationCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
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

#pragma mark - SNMLogManagerListener

- (void)onProcessingLog:(id<SNMLog>)log withPriority:(SNMPriority)priority {

  // Start session log is created in this method, therefore, skip in order to avoid infinite loop.
  if ([((NSObject *)log) isKindOfClass:[SNMStartSessionLog class]])
    return;

  if (log.toffset != nil) {
    [self.pastSessions
        enumerateObjectsUsingBlock:^(SNMSessionHistoryInfo *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
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
