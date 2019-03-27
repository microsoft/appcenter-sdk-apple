// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSKeychainAuthTokenStorage.h"
#import "MSAppCenterInternal.h"
#import "MSAuthTokenHistoryState.h"
#import "MSAuthTokenInfo.h"
#import "MSConstants.h"
#import "MSKeychainUtil.h"
#import "MSLogger.h"
#import "MSUtility.h"

@interface MSKeychainAuthTokenStorage ()

/**
 * Private field used to get and set auth tokens history array.
 */
@property(nullable, nonatomic) NSArray<MSAuthTokenInfo *> *authTokenHistoryArray;

@end

@implementation MSKeychainAuthTokenStorage

- (nullable NSString *)authToken {
  NSArray<MSAuthTokenInfo *> *authTokenHistory = [self authTokenHistory];
  MSAuthTokenInfo *latestAuthTokenInfo = authTokenHistory.lastObject;
  return latestAuthTokenInfo.authToken;
}

- (nullable NSString *)accountId {
  return [MS_USER_DEFAULTS objectForKey:kMSHomeAccountKey];
}

- (NSMutableArray<MSAuthTokenHistoryState *> *)authTokenArray {
  NSMutableArray<MSAuthTokenInfo *> *__nullable tokenArray =
      (NSMutableArray<MSAuthTokenInfo *> * __nullable)[MSKeychainUtil arrayForKey:kMSAuthTokenArrayKey];
  NSMutableArray<MSAuthTokenHistoryState *> *resultArray = [NSMutableArray<MSAuthTokenHistoryState *> new];
  if (!tokenArray || tokenArray.count == 0) {
    return nil;
  }
  for (NSUInteger i = 0; i < tokenArray.count; i++) {
    MSAuthTokenInfo *currentAuthTokenInfo = tokenArray[i];
    NSDate *endTime = currentAuthTokenInfo.endTime;
    NSDate *nextTokenStartTime = i + 1 < tokenArray.count ? tokenArray[i + 1].startTime : nil;
    if (nextTokenStartTime && endTime && [nextTokenStartTime laterDate:endTime]) {
      endTime = nextTokenStartTime;
    } else if (!endTime && nextTokenStartTime) {
      endTime = nextTokenStartTime;
    }
    [resultArray addObject:[[MSAuthTokenHistoryState alloc] initWithAuthToken:currentAuthTokenInfo.authToken
                                                                 andStartTime:currentAuthTokenInfo.startTime
                                                                   andEndTime:endTime]];
  }
  return resultArray;
}

- (void)saveAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId expiresOn:(nullable NSDate *)expiresOn {
  @synchronized(self) {

    // Read token array from storage.
    NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [[self authTokenHistory] mutableCopy];
    if (authTokenHistory.count == 0) {

      /*
       * Adding a nil entry is required during the first initialization to differentiate
       * anonymous usage before the moment and situation when we don't have a token
       * in history because of the size limit for example.
       */
      [authTokenHistory addObject:[MSAuthTokenInfo new]];
    }

    // If new token differs from the last token of array - add it to array.
    NSString *latestAuthToken = [authTokenHistory lastObject].authToken;
    if (latestAuthToken ? ![latestAuthToken isEqualToString:(NSString * _Nonnull) authToken] : authToken != nil) {
      MSAuthTokenInfo *newAuthToken = [[MSAuthTokenInfo alloc] initWithAuthToken:authToken
                                                                    andAccountId:accountId
                                                                    andStartTime:[NSDate date]
                                                                      andEndTime:expiresOn];
      [authTokenHistory addObject:newAuthToken];
    }

    // Cap array size at max available size const (deleting from beginning).
    if ([authTokenHistory count] > kMSMaxAuthTokenArraySize) {
      [authTokenHistory removeObjectAtIndex:0];
    }

    // Save new array.
    [self setAuthTokenHistory:authTokenHistory];
    if (authToken && accountId) {
      [MS_USER_DEFAULTS setObject:(NSString *)accountId forKey:kMSHomeAccountKey];
    } else {
      [MS_USER_DEFAULTS removeObjectForKey:kMSHomeAccountKey];
    }
  }
}

- (void)removeAuthToken:(nullable NSString *)authToken {
  @synchronized(self) {

    // Read token array from storage.
    NSMutableArray<MSAuthTokenInfo *> *tokenArray = [[self authTokenHistory] mutableCopy];

    // Do nothing if there's just one entry in the history or no history at all.
    if (!tokenArray || tokenArray.count == 1) {
      return;
    }

    // Find, delete the oldest entry. Do not delete the most recent entry.
    for (NSUInteger i = 0; i < tokenArray.count - 1; i++) {
      if ([tokenArray[i] authToken] == authToken) {
        [tokenArray removeObjectAtIndex:i];
        break;
      }
    }

    // Save new array after changes.
    [self setAuthTokenHistory:tokenArray];
  }
}

- (NSArray<MSAuthTokenInfo *> *)authTokenHistory {
  if (self.authTokenHistoryArray) {
    return self.authTokenHistoryArray;
  }
  NSArray<MSAuthTokenInfo *> *history = [MSKeychainUtil arrayForKey:kMSAuthTokenArrayKey];
  if (history) {
    MSLogDebug([MSAppCenter logTag], @"Retrieved history state from the keychain.");
  } else {
    MSLogWarning([MSAppCenter logTag], @"Failed to retrieve history state from the keychain or none was found.");
    history = [NSArray<MSAuthTokenInfo *> new];
  }
  self.authTokenHistoryArray = history;
  return self.authTokenHistoryArray;
}

- (void)setAuthTokenHistory:(nullable NSArray<MSAuthTokenInfo *> *)authTokenHistory {
  if ([MSKeychainUtil storeArray:(NSArray * __nonnull) authTokenHistory forKey:kMSAuthTokenArrayKey]) {
    MSLogDebug([MSAppCenter logTag], @"Saved new history state in the keychain.");
    self.authTokenHistoryArray = authTokenHistory;
  } else {
    MSLogWarning([MSAppCenter logTag], @"Failed to save new history state in the keychain.");
  }
}

@end
