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

- (nullable NSString *)retrieveAuthToken {
  NSString *authToken = [MSKeychainUtil stringForKey:kMSIdentityAuthTokenKey];
  if (authToken) {
    MSLogDebug([MSIdentity logTag], @"Retrieved auth token from keychain.");
  } else {
    MSLogWarning([MSIdentity logTag], @"Failed to retrieve auth token from keychain or none was found.");
  }
  return authToken;
}

- (nullable NSString *)retrieveAccountId {
  return [MS_USER_DEFAULTS objectForKey:kMSIdentityMSALAccountHomeAccountKey];
}

// TODO: This method will be used to retrieve logs from DB for a period when token was active.
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
    NSMutableArray<MSAuthTokenInfo *> *tokenArray = [MSKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];
    if (!tokenArray) {
      tokenArray = [NSMutableArray<MSAuthTokenInfo *> new];
    }
    if (tokenArray.count == 0) {

      // Add nil token if the entire story is empty.
      [tokenArray addObject:[MSAuthTokenInfo new]];
    }
    if (![tokenArray.lastObject.authToken isEqual:authToken]) {

      // If new token differs from the last token of array - add it to array.
      MSAuthTokenInfo *newAuthToken = [[MSAuthTokenInfo alloc] initWithAuthToken:authToken andStartTime:[NSDate date] andEndTime:expiresOn];
      [tokenArray addObject:newAuthToken];
    }

    // Cap array size at max available size const (deleting from beginning).
    if ([tokenArray count] > kMSIdentityMaxAuthTokenArraySize) {
      [tokenArray removeObjectAtIndex:0];
    }

    // Save new array.
    if ([MSKeychainUtil storeArray:tokenArray forKey:kMSIdentityAuthTokenArrayKey]) {
      MSLogDebug([MSIdentity logTag], @"Saved new history state in keychain.");
    } else {
      MSLogWarning([MSIdentity logTag], @"Failed to save new history state in keychain.");
    }
    if (authToken) {
      [self saveTokenToKeychain:authToken];
    } else {
      [self deleteTokenFromKeychain];
    }
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
    NSMutableArray<MSAuthTokenInfo *> *tokenArray = [MSKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];

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
    [MSKeychainUtil storeArray:tokenArray forKey:kMSIdentityAuthTokenArrayKey];
  }
   */
}

- (void)deleteTokenFromKeychain {
  if ([MSKeychainUtil deleteStringForKey:kMSIdentityAuthTokenKey]) {
    MSLogDebug([MSIdentity logTag], @"Deleted auth token from keychain.");
  } else {
    MSLogWarning([MSIdentity logTag], @"Failed to delete auth token from keychain.");
  };
}

- (void)saveTokenToKeychain:(nullable NSString *)authToken {
  if ([MSKeychainUtil storeString:(NSString *)authToken forKey:kMSIdentityAuthTokenKey]) {
    MSLogDebug([MSIdentity logTag], @"Saved new auth token in keychain.");
  } else {
    MSLogWarning([MSIdentity logTag], @"Failed to save new auth token in keychain.");
  }
}

@end
