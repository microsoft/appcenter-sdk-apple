#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSLogger.h"
#import "MSUserIdContextPrivate.h"
#import "MSUtility.h"

/**
 * Maximum allowed length for user identifier for App Center server.
 */
static const int kMSMaxUserIdLength = 256;

/*
 * Custom User ID prefix for Common Schema.
 */
static NSString *const kMSUserIdCustomPrefix = @"c";

/**
 * User Id history key.
 */
static NSString *const kMSUserIdHistoryKey = @"UserIdHistory";

/**
 * Singleton.
 */
static MSUserIdContext *sharedInstance;
static dispatch_once_t onceToken;

@implementation MSUserIdContext

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[MSUserIdContext alloc] init];
    }
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSData *data = [MS_USER_DEFAULTS objectForKey:kMSUserIdHistoryKey];
    if (data != nil) {
      _userIdHistory = (NSMutableArray *)[(NSObject *)[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];
    }
    if (!_userIdHistory) {
      _userIdHistory = [NSMutableArray<MSUserIdHistoryInfo *> new];
    }
    NSUInteger count = [_userIdHistory count];
    MSLogDebug([MSAppCenter logTag], @"%tu userId(s) in the history.", count);

    // Set nil to current userId so that it can return nil for the userId between App Center start and setUserId call.
    _currentUserIdInfo = [[MSUserIdHistoryInfo alloc] initWithTimestamp:[NSDate date] andUserId:nil];
    [_userIdHistory addObject:_currentUserIdInfo];

    /*
     * Persist nil userId as a current userId to NSUserDefaults so that Crashes can retrieve a correct userId when apps crash between App
     * Center start and setUserId call.
     */
    [MS_USER_DEFAULTS setObject:[NSKeyedArchiver archivedDataWithRootObject:self.userIdHistory] forKey:kMSUserIdHistoryKey];
  }
  return self;
}

+ (void)resetSharedInstance {
  onceToken = 0;
  sharedInstance = nil;
}

- (NSString *)userId {
  return [self currentUserIdInfo].userId;
}

- (void)setUserId:(nullable NSString *)userId {
  @synchronized(self) {

    /*
     * Replacing the last userId from history because the userId has changed within a same lifecycle without crashes.
     * The userId history is only used to correlate a crashes log with a userId, previous userId won't be used at all since there is no
     * crashes on apps between previous userId and current userId.
     */
    [self.userIdHistory removeLastObject];
    self.currentUserIdInfo.userId = userId;
    self.currentUserIdInfo.timestamp = [NSDate date];
    [self.userIdHistory addObject:self.currentUserIdInfo];
    [MS_USER_DEFAULTS setObject:[NSKeyedArchiver archivedDataWithRootObject:self.userIdHistory] forKey:kMSUserIdHistoryKey];
    MSLogVerbose([MSAppCenter logTag], @"Stored new userId:%@ and timestamp: %@.", self.currentUserIdInfo.userId,
                 self.currentUserIdInfo.timestamp);
  }
}

- (nullable NSString *)userIdAt:(NSDate *)date {
  @synchronized(self) {
    for (MSUserIdHistoryInfo *info in [self.userIdHistory reverseObjectEnumerator]) {
      if ([info.timestamp compare:date] == NSOrderedAscending) {
        return info.userId;
      }
    }
    return nil;
  }
}

- (void)clearUserIdHistory {
  @synchronized(self) {
    [self.userIdHistory removeAllObjects];
    [self.userIdHistory addObject:self.currentUserIdInfo];
    [MS_USER_DEFAULTS setObject:[NSKeyedArchiver archivedDataWithRootObject:self.userIdHistory] forKey:kMSUserIdHistoryKey];
    MSLogVerbose([MSAppCenter logTag], @"Cleared old userIds while keeping current userId.");
  }
}

+ (BOOL)isUserIdValidForAppCenter:(nullable NSString *)userId {
  if (userId && userId.length > kMSMaxUserIdLength) {
    MSLogError([MSAppCenter logTag], @"userId is limited to %d characters.", kMSMaxUserIdLength);
    return NO;
  }
  return YES;
}

+ (BOOL)isUserIdValidForOneCollector:(nullable NSString *)userId {
  if (!userId) {
    return YES;
  }
  NSRange separator = [userId rangeOfString:kMSCommonSchemaPrefixSeparator];
  if (userId.length == 0) {
    MSLogError([MSAppCenter logTag], @"userId must not be empty.");
    return NO;
  }
  if (separator.location != NSNotFound) {
    NSString *prefix = [userId substringToIndex:separator.location];
    if (![prefix isEqualToString:kMSUserIdCustomPrefix]) {
      MSLogError([MSAppCenter logTag], @"userId prefix must be '%@', '%@' is not supported.", kMSUserIdCustomPrefix, prefix);
      return NO;
    } else if (separator.location == userId.length - 1) {
      MSLogError([MSAppCenter logTag], @"userId must not be empty.");
      return NO;
    }
  }
  return YES;
}

+ (nullable NSString *)prefixedUserIdFromUserId:(nullable NSString *)userId {
  if (userId && [userId rangeOfString:kMSCommonSchemaPrefixSeparator].location == NSNotFound) {
    return [NSString stringWithFormat:@"%@%@%@", kMSUserIdCustomPrefix, kMSCommonSchemaPrefixSeparator, userId];
  }
  return userId;
}

@end
