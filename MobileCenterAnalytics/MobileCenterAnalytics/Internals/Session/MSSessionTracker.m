/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAnalyticsInternal.h"
#import "MSSessionTracker.h"
#import "MSStartSessionLog.h"

static NSTimeInterval const kMSSessionTimeOut = 20;
static NSString *const kMSPastSessionsKey = @"pastSessionsKey";
static NSUInteger const kMSMaxSessionHistoryCount = 5;

@interface MSSessionTracker ()

/**
 * Current session id.
 */
@property(nonatomic, readwrite) NSString *sessionId;

/**
 *  Flag to indicate if session tracking has started or not.
 */
@property(nonatomic) BOOL started;

/**
 *  Check if current session has timed out.
 *
 *  @return YES if current session has timed out, NO otherwise.
 */
- (BOOL)hasSessionTimedOut;

@end

@implementation MSSessionTracker

- (instancetype)init {
  if (self = [super init]) {
    _sessionTimeout = kMSSessionTimeOut;

    // Restore past sessions from NSUserDefaults.
    NSData *sessions = [kMSUserDefaults objectForKey:kMSPastSessionsKey];
    if (sessions != nil) {
      NSArray *arrayFromData = [NSKeyedUnarchiver unarchiveObjectWithData:sessions];

      // If array is not nil, create a mutable version.
      if (arrayFromData)
        _pastSessions = [NSMutableArray arrayWithArray:arrayFromData];
    }

    // Create new array.
    if (_pastSessions == nil)
      _pastSessions = [NSMutableArray<MSSessionHistoryInfo *> new];

    // Session tracking is not started by default.
    _started = NO;
  }
  return self;
}

- (NSString *)sessionId {
  @synchronized(self) {

    // Check if new session id is required.
    if (_sessionId == nil || [self hasSessionTimedOut]) {
      _sessionId = kMSUUIDString;

      // Record session.
      MSSessionHistoryInfo *sessionInfo = [[MSSessionHistoryInfo alloc] init];
      sessionInfo.sessionId = _sessionId;
      sessionInfo.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

      // Insert at the beginning of the list.
      [self.pastSessions insertObject:sessionInfo atIndex:0];

      // Remove last item if reached max limit.
      if ([self.pastSessions count] > kMSMaxSessionHistoryCount)
        [self.pastSessions removeLastObject];

      // Persist the session history in NSData format.
      [kMSUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.pastSessions]
                           forKey:kMSPastSessionsKey];
      MSLogInfo([MSAnalytics getLoggerTag], @"New session ID: %@", _sessionId);

      // Create a start session log.
      MSStartSessionLog *log = [[MSStartSessionLog alloc] init];
      log.sid = _sessionId;
      [self.delegate sessionTracker:self processLog:log withPriority:MSPriorityDefault];
    }
    return _sessionId;
  }
}

- (void)start {
  if (!_started) {

    // Renew session as needed if app is not in the background.
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
      [self sessionId];
    }

    // Hookup to application events.
    [kMSNotificationCenter addObserver:self
                               selector:@selector(applicationDidEnterBackground)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
    [kMSNotificationCenter addObserver:self
                               selector:@selector(applicationWillEnterForeground)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
    _started = YES;
  }
}

- (void)stop {
  if (_started) {
    [kMSNotificationCenter removeObserver:self];
    _started = NO;
  }
}

- (void)clearSessions {
  @synchronized(self) {

    // Clear persistence.
    [kMSUserDefaults removeObjectForKey:kMSPastSessionsKey];

    // Clear cache.
    self.sessionId = nil;
    [self.pastSessions removeAllObjects];
  }
}

#pragma mark - private methods

- (BOOL)hasSessionTimedOut {

  @synchronized(self) {
    NSDate *now = [NSDate date];

    // Verify if a log has already been sent and if it was sent a longer time ago than the session timeout.
    BOOL noLogSentForLong =
        !self.lastCreatedLogTime || [now timeIntervalSinceDate:self.lastCreatedLogTime] >= self.sessionTimeout;

    // Verify if app is currently in the background for a longer time than the session timeout.
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

  // Trigger session renewal.
  [self sessionId];
}

#pragma mark - MSLogManagerDelegate

- (void)onProcessingLog:(id<MSLog>)log withPriority:(MSPriority)priority {

  // Update time stamp.
  _lastCreatedLogTime = [NSDate date];

  // Start session log is created in this method, therefore, skip in order to avoid infinite loop.
  if ([((NSObject *)log) isKindOfClass:[MSStartSessionLog class]])
    return;

  // Attach corresponding session id.
  if (log.toffset != nil) {
    [self.pastSessions
        enumerateObjectsUsingBlock:^(MSSessionHistoryInfo *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
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
}

@end
