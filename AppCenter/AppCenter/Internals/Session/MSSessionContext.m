#import "MSAppCenterInternal.h"
#import "MSLogger.h"
#import "MSSessionContextPrivate.h"
#import "MSUtility.h"

/**
 * Base URL for HTTP Ingestion backend API calls.
 */
static NSString *const kMSSessionIdHistoryKey = @"SessionIdHistory";

/**
 * Singleton.
 */
static MSSessionContext *sharedInstance;
static dispatch_once_t onceToken;

@implementation MSSessionContext

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[self alloc] init];
      NSData *data = [MS_USER_DEFAULTS objectForKey:kMSSessionIdHistoryKey];
      if (data != nil) {
        sharedInstance.sessionHistory =
            (NSMutableArray *)[[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];
      }
      if (!sharedInstance.sessionHistory) {
        sharedInstance.sessionHistory = [NSMutableArray<MSSessionHistoryInfo *> new];
      }
      MSLogDebug([MSAppCenter logTag], @"%lu session(s) in the history.", (unsigned long)[sharedInstance.sessionHistory count]);
      sharedInstance.currentSessionInfo =
          [[MSSessionHistoryInfo alloc] initWithTimestamp:[NSDate date] andSessionId:nil];
      [sharedInstance.sessionHistory addObject:sharedInstance.currentSessionInfo];
    }
  });
  return sharedInstance;
}

+ (void)resetSharedInstance {
  onceToken = 0;
  sharedInstance = nil;
}

+ (void)setSessionId:(nullable NSString *)sessionId {
  [[self sharedInstance] setSessionId:sessionId];
}

+ (NSString *)sessionId {
  return [[self sharedInstance] currentSessionInfo].sessionId;
}

+ (NSString *)sessionIdAt:(NSDate *)date {
  return [[self sharedInstance] sessionIdAt:date];
}

+ (void)clearSessionHistory {
  [[self sharedInstance] clearSessionHistory];
}

- (void)setSessionId:(nullable NSString *)sessionId {
  @synchronized(self) {
    [self.sessionHistory removeLastObject];
    self.currentSessionInfo.sessionId = sessionId;
    self.currentSessionInfo.timestamp = [NSDate date];
    [self.sessionHistory addObject:self.currentSessionInfo];
    [MS_USER_DEFAULTS setObject:[NSKeyedArchiver archivedDataWithRootObject:self.sessionHistory]
                         forKey:kMSSessionIdHistoryKey];
    MSLogVerbose([MSAppCenter logTag], @"Stored new session with id:%@ and timestamp: %@.",
                 self.currentSessionInfo.sessionId, self.currentSessionInfo.timestamp);
  }
}

- (NSString *)sessionIdAt:(NSDate *)date {
  @synchronized(self) {
    for (MSSessionHistoryInfo *info in [self.sessionHistory reverseObjectEnumerator]) {
      if ([info.timestamp compare:date] == NSOrderedAscending) {
        return info.sessionId;
      }
    }
    return nil;
  }
}

- (void)clearSessionHistory {
  @synchronized(self) {
    [self.sessionHistory removeAllObjects];
    [self.sessionHistory addObject:self.currentSessionInfo];
    [MS_USER_DEFAULTS setObject:[NSKeyedArchiver archivedDataWithRootObject:self.sessionHistory]
                         forKey:kMSSessionIdHistoryKey];
    MSLogVerbose([MSAppCenter logTag], @"Cleared old sessions.");
  }
}

@end
