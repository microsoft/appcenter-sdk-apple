// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContext.h"

/**
 * Singleton.
 */
static MSAuthTokenContext *sharedInstance;
static dispatch_once_t onceToken;

@interface MSAuthTokenContext ()

/**
 * Private field used to get and set auth tokens history array.
 */
@property(nullable, nonatomic) NSArray<MSAuthTokenInfo *> *authTokenHistoryArray;

/**
 * Cached authorization token.
 */
@property(nullable, atomic, copy) NSString *authTokenCache;

/**
 * Collection of channel delegates.
 */
@property(nonatomic) NSHashTable<id<MSAuthTokenContextDelegate>> *delegates;

@end

@implementation MSAuthTokenContext

- (instancetype)init {
  self = [super init];
  if (self) {
    _delegates = [NSHashTable new];
  }
  return self;
}

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [MSAuthTokenContext new];
    }
  });
  return sharedInstance;
}

+ (void)resetSharedInstance {
  onceToken = 0;
  sharedInstance = nil;
}

- (void)setAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId expiresOn:(nullable NSDate *)expiresOn {
  NSArray *synchronizedDelegates;
  BOOL isNewUser = NO;
  @synchronized(self) {
    isNewUser = ![self.accountId isEqual:accountId];

    // Don't invoke the delegate while locking; it might be locking too and deadlock ourselves.
    synchronizedDelegates = [self.delegates allObjects];
    [self saveAuthToken:authToken withAccountId:accountId expiresOn:expiresOn];
  }
  for (id<MSAuthTokenContextDelegate> delegate in synchronizedDelegates) {
    if ([delegate respondsToSelector:@selector(authTokenContext:didSetNewAuthToken:)]) {
      [delegate authTokenContext:self didSetNewAuthToken:authToken];
    }
    if (isNewUser && [delegate respondsToSelector:@selector(authTokenContext:didSetNewAccountIdWithAuthToken:)]) {
      [delegate authTokenContext:self didSetNewAccountIdWithAuthToken:authToken];
    }
  }
}

- (void)addDelegate:(id<MSAuthTokenContextDelegate>)delegate {
  @synchronized(self) {
    [self.delegates addObject:delegate];
  }
}

- (void)removeDelegate:(id<MSAuthTokenContextDelegate>)delegate {
  @synchronized(self) {
    [self.delegates removeObject:delegate];
  }
}

- (nullable NSString *)authToken {
  NSArray<MSAuthTokenInfo *> *authTokenHistory = [self authTokenHistory];
  MSAuthTokenInfo *latestAuthTokenInfo = authTokenHistory.lastObject;
  return latestAuthTokenInfo.authToken;
}

- (nullable NSString *)accountId {
  NSArray<MSAuthTokenInfo *> *authTokenHistory = [self authTokenHistory];
  MSAuthTokenInfo *latestAuthTokenInfo = authTokenHistory.lastObject;
  return latestAuthTokenInfo.accountId;
}

- (NSMutableArray<MSAuthTokenValidityInfo *> *)authTokenValidityArray {
  NSMutableArray<MSAuthTokenInfo *> *__nullable tokenArray =
      (NSMutableArray<MSAuthTokenInfo *> * __nullable)[MSKeychainUtil arrayForKey:kMSAuthTokenHistoryKey];
  NSMutableArray<MSAuthTokenValidityInfo *> *resultArray = [NSMutableArray<MSAuthTokenValidityInfo *> new];
  if (!tokenArray || tokenArray.count == 0) {
    [resultArray addObject:[[MSAuthTokenValidityInfo alloc] initWithAuthToken:nil andStartTime:nil andExpiresOn:nil]];
    return resultArray;
  }
  for (NSUInteger i = 0; i < tokenArray.count; i++) {
    MSAuthTokenInfo *currentAuthTokenInfo = tokenArray[i];
    NSDate *expiresOn = currentAuthTokenInfo.expiresOn;
    NSDate *nextTokenStartTime = i + 1 < tokenArray.count ? tokenArray[i + 1].startTime : nil;
    if (nextTokenStartTime && expiresOn && [nextTokenStartTime laterDate:expiresOn]) {
      expiresOn = nextTokenStartTime;
    } else if (!expiresOn && nextTokenStartTime) {
      expiresOn = nextTokenStartTime;
    }
    [resultArray addObject:[[MSAuthTokenValidityInfo alloc] initWithAuthToken:currentAuthTokenInfo.authToken
                                                                 andStartTime:currentAuthTokenInfo.startTime
                                                                 andExpiresOn:expiresOn]];
  }
  return resultArray;
}

- (void)saveAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId expiresOn:(nullable NSDate *)expiresOn {
  @synchronized(self) {

    // Read token array from storage.
    NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [[self authTokenHistory] mutableCopy];

    // If new token differs from the last token of array - add it to array.
    MSAuthTokenInfo *lastEntry = authTokenHistory.lastObject;
    NSString *__nullable latestAuthToken = lastEntry.authToken;
    NSString *__nullable latestAccountId = lastEntry.accountId;
    NSDate *__nullable latestTokenEndTime = lastEntry.expiresOn;
    if (latestAuthToken ? ![latestAuthToken isEqualToString:(NSString * _Nonnull) authToken] : authToken != nil) {
      BOOL isNewUser = authTokenHistory.lastObject == nil || ![accountId isEqualToString:(NSString * __nonnull) latestAccountId];
      NSDate *newTokenStartDate = [NSDate date];

      // If there is a gap between tokens.
      if (latestTokenEndTime && [newTokenStartDate laterDate:(NSDate * __nonnull) latestTokenEndTime]) {

        // If the account the same or become anonymous.
        if (!isNewUser || authToken == nil) {

          // Apply the new token to this time.
          newTokenStartDate = latestTokenEndTime;
        } else {

          // If it's not the same account treat the gap as anonymous.
          MSAuthTokenInfo *newAuthToken = [[MSAuthTokenInfo alloc] initWithAuthToken:nil
                                                                        andAccountId:nil
                                                                        andStartTime:lastEntry.expiresOn
                                                                        andExpiresOn:newTokenStartDate];
          [authTokenHistory addObject:newAuthToken];
        }
      }
      MSAuthTokenInfo *newAuthToken = [[MSAuthTokenInfo alloc] initWithAuthToken:authToken
                                                                    andAccountId:accountId
                                                                    andStartTime:newTokenStartDate
                                                                    andExpiresOn:expiresOn];
      [authTokenHistory addObject:newAuthToken];
    }

    // Cap array size at max available size const (deleting from beginning).
    if ([authTokenHistory count] > kMSMaxAuthTokenArraySize) {
      [authTokenHistory removeObjectsInRange:(NSRange){0, [authTokenHistory count] - kMSMaxAuthTokenArraySize}];
      MSLogWarning([MSAppCenter logTag], @"Size of the token history is exceeded. The oldest token has been removed.");
    }

    // Save new array.
    [self setAuthTokenHistory:authTokenHistory];
  }
}

- (void)removeAuthToken:(nullable NSString *)authToken {
  @synchronized(self) {

    // Read token array from storage.
    NSMutableArray<MSAuthTokenInfo *> *tokenArray = [[self authTokenHistory] mutableCopy];

    // Do nothing if there's just one entry in the history or no history at all.
    if (!tokenArray || tokenArray.count <= 1) {
      MSLogWarning([MSAppCenter logTag], @"Couldn't remove token from history; token history is empty or contains only current one.");
      return;
    }

    // Check oldest entry, delete if it matches.
    if (tokenArray[0].authToken == authToken) {
      [tokenArray removeObjectAtIndex:0];
    } else {
      MSLogWarning([MSAppCenter logTag], @"Couldn't remove token from history; the token isn't oldest or is already removed.");
    }

    // Save new array after changes.
    [self setAuthTokenHistory:tokenArray];
    MSLogDebug([MSAppCenter logTag], @"The token has been removed from the history.");
  }
}

- (NSArray<MSAuthTokenInfo *> *)authTokenHistory {
  if (self.authTokenHistoryArray != nil) {
    return (NSArray<MSAuthTokenInfo *> *)self.authTokenHistoryArray;
  }
  NSArray<MSAuthTokenInfo *> *history = [MSKeychainUtil arrayForKey:kMSAuthTokenHistoryKey];
  if (history) {
    MSLogDebug([MSAppCenter logTag], @"Retrieved history state from the keychain.");
  } else {
    MSLogWarning([MSAppCenter logTag], @"Failed to retrieve history state from the keychain or none was found.");
    history = [NSArray<MSAuthTokenInfo *> new];
  }
  self.authTokenHistoryArray = history;
  return (NSArray<MSAuthTokenInfo *> *)self.authTokenHistoryArray;
}

- (void)setAuthTokenHistory:(nullable NSArray<MSAuthTokenInfo *> *)authTokenHistory {
  if ([MSKeychainUtil storeArray:(NSArray * __nonnull) authTokenHistory forKey:kMSAuthTokenHistoryKey]) {
    MSLogDebug([MSAppCenter logTag], @"Saved new history state in the keychain.");
    self.authTokenHistoryArray = authTokenHistory;
  } else {
    MSLogWarning([MSAppCenter logTag], @"Failed to save new history state in the keychain.");
  }
}

@end
