#import "MSAppCenterInternal.h"
#import "MSLogger.h"
#import "MSSessionContextPrivate.h"
#import "MSUtility.h"

/**
 * Storage key for history data.
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
      sharedInstance = [[MSSessionContext alloc] init];
    }
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSData *data = [MS_USER_DEFAULTS objectForKey:kMSSessionIdHistoryKey];
    if (data != nil) {
      _sessionHistory = (NSMutableArray *)[(NSObject *)[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];
    }
    if (!_sessionHistory) {
      _sessionHistory = [NSMutableArray<MSSessionHistoryInfo *> new];
    }
    NSUInteger count = [_sessionHistory count];
    MSLogDebug([MSAppCenter logTag], @"%tu session(s) in the history.", count);
    _currentSessionInfo = [[MSSessionHistoryInfo alloc] initWithTimestamp:[NSDate date] andSessionId:nil];
    [_sessionHistory addObject:_currentSessionInfo];
  }
  return self;
}

+ (void)resetSharedInstance {
  onceToken = 0;
  sharedInstance = nil;
}

- (NSString *)sessionId {
  return [self currentSessionInfo].sessionId;
}

- (void)setSessionId:(nullable NSString *)sessionId {
  @synchronized(self) {
    [self.sessionHistory removeLastObject];
    self.currentSessionInfo.sessionId = sessionId;
    self.currentSessionInfo.timestamp = [NSDate date];
    [self.sessionHistory addObject:self.currentSessionInfo];
    [MS_USER_DEFAULTS setObject:[NSKeyedArchiver archivedDataWithRootObject:self.sessionHistory] forKey:kMSSessionIdHistoryKey];
    MSLogVerbose([MSAppCenter logTag], @"Stored new session with id:%@ and timestamp: %@.", self.currentSessionInfo.sessionId,
                 self.currentSessionInfo.timestamp);
  }
}

- (nullable NSString *)sessionIdAt:(NSDate *)date {
  @synchronized(self) {
    for (MSSessionHistoryInfo *info in [self.sessionHistory reverseObjectEnumerator]) {
      if ([info.timestamp compare:date] == NSOrderedAscending) {
        return info.sessionId;
      }
    }
    return nil;
  }
}

- (void)clearSessionHistoryAndKeepCurrentSession:(BOOL)keepCurrentSession {
  @synchronized(self) {
    [self.sessionHistory removeAllObjects];
    if (keepCurrentSession) {
      [self.sessionHistory addObject:self.currentSessionInfo];
    }
    [MS_USER_DEFAULTS setObject:[NSKeyedArchiver archivedDataWithRootObject:self.sessionHistory] forKey:kMSSessionIdHistoryKey];
    MSLogVerbose([MSAppCenter logTag], @"Cleared old sessions.");
  }
}

@end
