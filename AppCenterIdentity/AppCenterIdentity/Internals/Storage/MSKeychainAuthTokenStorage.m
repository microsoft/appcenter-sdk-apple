// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSKeychainAuthTokenStorage.h"
#import "MSAuthTokenHistoryState.h"
#import "MSAuthTokenInfo.h"
#import "MSIdentityConstants.h"
#import "MSIdentityPrivate.h"
#import "MSKeychainUtil.h"
#import "MSLogger.h"
#import "MSUtility.h"

@implementation MSKeychainAuthTokenStorage

@synthesize authTokensHistory = _authTokensHistory;

- (nullable NSString *)retrieveAuthToken {
  NSArray<MSAuthTokenInfo *> *authTokensHistoryState = [self authTokensHistory];
  MSAuthTokenInfo *latestAuthTokenInfo = authTokensHistoryState.lastObject;
  return latestAuthTokenInfo.authToken;
}

- (nullable NSString *)retrieveAccountId {
  return [MS_USER_DEFAULTS objectForKey:kMSIdentityMSALAccountHomeAccountKey];
}

- (NSMutableArray<MSAuthTokenHistoryState *> *)authTokenArray {
  NSMutableArray<MSAuthTokenInfo *> *__nullable tokenArray = [MSKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];
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
    NSMutableArray<MSAuthTokenInfo *> *authTokensHistory = [[self authTokensHistory] mutableCopy];
    if (authTokensHistory.count == 0) {

      /*
       * Adding a nil entry is required during the first initialization to differentiate
       * anonymous usage before the moment and situation when we don't have a token
       * in history because of the size limit for example.
       */
      [authTokensHistory addObject:[MSAuthTokenInfo new]];
    }

    // If new token differs from the last token of array - add it to array.
    NSString *latestAuthToken = [authTokensHistory lastObject].authToken;
    if (latestAuthToken ? ![latestAuthToken isEqualToString:(NSString * _Nonnull) authToken] : authToken != nil) {
      MSAuthTokenInfo *newAuthToken = [[MSAuthTokenInfo alloc] initWithAuthToken:authToken
                                                                    andAccountId:accountId
                                                                    andStartTime:[NSDate date]
                                                                      andEndTime:expiresOn];
      [authTokensHistory addObject:newAuthToken];
    }

    // Cap array size at max available size const (deleting from beginning).
    if ([authTokensHistory count] > kMSIdentityMaxAuthTokenArraySize) {
      [authTokensHistory removeObjectAtIndex:0];
    }

    // Save new array.
    [self setAuthTokensHistory:authTokensHistory];
    if (authToken && accountId) {
      [MS_USER_DEFAULTS setObject:(NSString *)accountId forKey:kMSIdentityMSALAccountHomeAccountKey];
    } else {
      [MS_USER_DEFAULTS removeObjectForKey:kMSIdentityMSALAccountHomeAccountKey];
    }
  }
}

- (void)removeAuthToken:(nullable NSString *)authToken {
  @synchronized(self) {

    // Read token array from storage.
    NSMutableArray<MSAuthTokenInfo *> *__nullable tokenArray = [self authTokensHistoryState];

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
    [self setAuthTokensHistoryState:tokenArray];
  }
}

- (NSArray<MSAuthTokenInfo *> *)authTokensHistory {
  if (_authTokensHistory) {
    return _authTokensHistory;
  }
  NSArray<MSAuthTokenInfo *> *history = [MSKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];
  if (history) {
    MSLogDebug([MSIdentity logTag], @"Retrieved history state from the keychain.");
  } else {
    MSLogWarning([MSIdentity logTag], @"Failed to retrieve history state from the keychain or none was found.");
    history = [NSArray<MSAuthTokenInfo *> new];
  }
  _authTokensHistory = history;
  return _authTokensHistory;
}

- (void)setAuthTokensHistoryState:(nullable NSMutableArray<MSAuthTokenInfo *> *)authTokensHistory {
  if ([MSKeychainUtil storeArray:authTokensHistory forKey:kMSIdentityAuthTokenArrayKey]) {
    MSLogDebug([MSIdentity logTag], @"Saved new history state in the keychain.");
    _authTokensHistory = authTokensHistory;
  } else {
    MSLogWarning([MSIdentity logTag], @"Failed to save new history state in the keychain.");
  }
}

@end
