// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSKeychainAuthTokenStorage.h"
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

// TODO: Finish the implementation, this method will be used to get logs from DB for a period when token was active.
- (MSAuthTokenInfo *)oldestAuthToken {
  return [MSAuthTokenInfo new];

  /*
  // Read token array from storage.
  NSMutableArray<MSAuthTokenInfo *> *tokenArray = [MSKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];
  if (!tokenArray || tokenArray.count == 0) {
    return nil;
  }

  MSAuthTokenInfo *authTokenInfo = tokenArray.firstObject;
  NSDate *nextChangeTime = tokenArray.count > 1 ? tokenArray[1].startTime : nil;
  if ([authTokenInfo.endTime laterDate:nextChangeTime]) {
    return [[MSAuthTokenInfo alloc] initWithAuthToken:authTokenInfo.authToken
                                         andStartTime:authTokenInfo.startTime
                                           andEndTime:nextChangeTime];
  }
  return authTokenInfo;
   */
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
      MSAuthTokenInfo *newAuthToken = [[MSAuthTokenInfo alloc] initWithAuthToken:authToken andStartTime:[NSDate date] andEndTime:expiresOn];
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

// TODO: Finish the implementation of tokens removal as part of the separate PR.
- (void)removeAuthToken:(nullable NSString *)__unused authToken {
  /*
  @synchronized(self) {

    // Read token array from storage.
    NSMutableArray<MSAuthTokenInfo *> *tokenArray = [self authTokensHistory];

    // TODO: Allow only the oldest token to be removed.
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
    [self storeAuthTokensHistoryState:tokenArray];
  }
   */
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

- (void)setAuthTokensHistory:(NSArray<MSAuthTokenInfo *> *)authTokensHistory {
  if ([MSKeychainUtil storeArray:authTokensHistory forKey:kMSIdentityAuthTokenArrayKey]) {
    MSLogDebug([MSIdentity logTag], @"Saved new history state in the keychain.");
    _authTokensHistory = authTokensHistory;
  } else {
    MSLogWarning([MSIdentity logTag], @"Failed to save new history state in the keychain.");
  }
}

@end
