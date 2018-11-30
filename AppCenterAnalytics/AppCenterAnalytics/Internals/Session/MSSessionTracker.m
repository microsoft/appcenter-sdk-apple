#import "MSSessionTracker.h"
#import "MSAnalyticsInternal.h"
#import "MSSessionContext.h"
#import "MSSessionTrackerPrivate.h"
#import "MSStartServiceLog.h"
#import "MSStartSessionLog.h"

static NSTimeInterval const kMSSessionTimeOut = 20;
static NSString *const kMSPastSessionsKey = @"pastSessionsKey";

@interface MSSessionTracker ()

/**
 * Check if current session has timed out.
 *
 * @return YES if current session has timed out, NO otherwise.
 */
- (BOOL)hasSessionTimedOut;

@end

@implementation MSSessionTracker

- (instancetype)init {
  if ((self = [super init])) {
    _sessionTimeout = kMSSessionTimeOut;
    _context = [MSSessionContext sharedInstance];

    // Remove old session history from previous SDK versions.
    [MS_USER_DEFAULTS removeObjectForKey:kMSPastSessionsKey];

    // Session tracking is not started by default.
    _started = NO;
  }
  return self;
}

- (void)renewSessionId {
  @synchronized(self) {
    if (self.started) {

      // Check if new session id is required.
      if ([self.context sessionId] == nil || [self hasSessionTimedOut]) {
        NSString *sessionId = MS_UUID_STRING;
        [self.context setSessionId:sessionId];
        MSLogInfo([MSAnalytics logTag], @"New session ID: %@", sessionId);

        // Create a start session log.
        MSStartSessionLog *log = [[MSStartSessionLog alloc] init];
        log.sid = sessionId;
        [self.delegate sessionTracker:self processLog:log];
      }
    }
  }
}

- (void)start {
  if (!self.started) {
    self.started = YES;

    // Request a new session id depending on the application state.
    if ([MSUtility applicationState] == MSApplicationStateInactive || [MSUtility applicationState] == MSApplicationStateActive) {
      [self renewSessionId];
    }

    // Hookup to application events.
    [MS_NOTIFICATION_CENTER addObserver:self
                               selector:@selector(applicationDidEnterBackground)
#if TARGET_OS_OSX
                                   name:NSApplicationDidResignActiveNotification
#else
                                   name:UIApplicationDidEnterBackgroundNotification
#endif
                                 object:nil];
    [MS_NOTIFICATION_CENTER addObserver:self
                               selector:@selector(applicationWillEnterForeground)
#if TARGET_OS_OSX
                                   name:NSApplicationWillBecomeActiveNotification
#else
                                   name:UIApplicationWillEnterForegroundNotification
#endif
                                 object:nil];
  }
}

- (void)stop {
  if (self.started) {
    [MS_NOTIFICATION_CENTER removeObserver:self];
    self.started = NO;
    [self.context setSessionId:nil];
  }
}

- (void)dealloc {
  [MS_NOTIFICATION_CENTER removeObserver:self];
}

#pragma mark - private methods

- (BOOL)hasSessionTimedOut {

  @synchronized(self) {
    NSDate *now = [NSDate date];

    // Verify if a log has already been sent and if it was sent a longer time ago than the session timeout.
    BOOL noLogSentForLong = !self.lastCreatedLogTime || [now timeIntervalSinceDate:self.lastCreatedLogTime] >= self.sessionTimeout;

    // FIXME: There is no life cycle for app extensions yet so ignoring the background tests for now.
    if (MS_IS_APP_EXTENSION)
      return noLogSentForLong;

    // Verify if app is currently in the background for a longer time than the session timeout.
    BOOL isBackgroundForLong = (self.lastEnteredBackgroundTime && self.lastEnteredForegroundTime) &&
                               ([self.lastEnteredBackgroundTime compare:self.lastEnteredForegroundTime] == NSOrderedDescending) &&
                               ([now timeIntervalSinceDate:self.lastEnteredBackgroundTime] >= self.sessionTimeout);

    // Verify if app was in the background for a longer time than the session timeout time.
    BOOL wasBackgroundForLong =
        (self.lastEnteredBackgroundTime)
            ? [self.lastEnteredForegroundTime timeIntervalSinceDate:self.lastEnteredBackgroundTime] >= self.sessionTimeout
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
  [self renewSessionId];
}

#pragma mark - MSChannelDelegate

- (void)channel:(id<MSChannelProtocol>)__unused channel prepareLog:(id<MSLog>)log {

  /*
   * Start session log is created in this method, therefore, skip in order to avoid infinite loop. Also skip start service log as it's
   * always sent and should not trigger a session.
   */
  if ([((NSObject *)log) isKindOfClass:[MSStartSessionLog class]] || [((NSObject *)log) isKindOfClass:[MSStartServiceLog class]])
    return;

  // If the log requires session Id.
  if (![(NSObject *)log conformsToProtocol:@protocol(MSNoAutoAssignSessionIdLog)]) {
    log.sid = [self.context sessionId];
  }

  // Update last created log time stamp.
  self.lastCreatedLogTime = [NSDate date];
}

@end
