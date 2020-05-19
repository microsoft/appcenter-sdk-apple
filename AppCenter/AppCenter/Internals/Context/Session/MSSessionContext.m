// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

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
    NSData *data = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSSessionIdHistoryKey];
    if (data != nil) {
      if (@available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *)) {
        NSObject *unarchivedObject = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class]
                                                                           fromData:data
                                                                              error:nil];
        _sessionHistory = (NSMutableArray *)[unarchivedObject mutableCopy];
      } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        _sessionHistory = (NSMutableArray *)[(NSObject *)[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];
#pragma clang diagnostic pop
      }
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
    NSObject *archObj = nil;
    if (@available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *)) {
      archObj = [NSKeyedArchiver archivedDataWithRootObject:self.sessionHistory requiringSecureCoding:NO error:nil];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
      archObj = [NSKeyedArchiver archivedDataWithRootObject:self.sessionHistory];
#pragma clang diagnostic pop
    }
    [MS_APP_CENTER_USER_DEFAULTS setObject:archObj forKey:kMSSessionIdHistoryKey];
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
    NSObject *archObj = nil;
    if (@available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *)) {
      archObj = [NSKeyedArchiver archivedDataWithRootObject:self.sessionHistory requiringSecureCoding:NO error:nil];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
      archObj = [NSKeyedArchiver archivedDataWithRootObject:self.sessionHistory];
#pragma clang diagnostic pop
    }
    [MS_APP_CENTER_USER_DEFAULTS setObject:archObj forKey:kMSSessionIdHistoryKey];
    MSLogVerbose([MSAppCenter logTag], @"Cleared old sessions.");
  }
}

@end
