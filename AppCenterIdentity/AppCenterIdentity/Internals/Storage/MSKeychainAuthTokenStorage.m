// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenInfo.h"
#import "MSIdentityPrivate.h"
#import "MSIdentityConstants.h"
#import "MSKeychainAuthTokenStorage.h"
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

- (MSAuthTokenInfo *)oldestAuthToken {
  /*

   TODO:
   1. read history, deserialize (lazy cache?)
   2. return: token=history[0].token, starttime=history[0].time, endtime=history[1].time (or nil)

   */
  return nil;
}

- (void)saveAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId {
  /*

   TODO:
   1. read history, deserialize (lazy cache?)
   2. if there is no history at all, add null entry
   3. add token
   4. remove oldest if the limit is reached
   5. serialize, save new history

   */

  if (authToken) {
    BOOL success = [MSKeychainUtil storeString:(NSString *)authToken forKey:kMSIdentityAuthTokenKey];
    if (success) {
      MSLogDebug([MSIdentity logTag], @"Saved auth token in keychain.");
    } else {
      MSLogWarning([MSIdentity logTag], @"Failed to save auth token in keychain.");
    }
  } else {
    if ([MSKeychainUtil deleteStringForKey:kMSIdentityAuthTokenKey]) {
      MSLogDebug([MSIdentity logTag], @"Removed auth token from keychain.");
    } else {
      MSLogWarning([MSIdentity logTag], @"Failed to remove auth token from keychain or none was found.");
    }
  }
  if (authToken && accountId) {
    [MS_USER_DEFAULTS setObject:(NSString *)accountId forKey:kMSIdentityMSALAccountHomeAccountKey];
  } else {
    [MS_USER_DEFAULTS removeObjectForKey:kMSIdentityMSALAccountHomeAccountKey];
  }
}

- (void)removeAuthToken:(nullable NSString *)authToken {

  (void)authToken;
  /*

   TODO:
   1. read history, deserialize (lazy cache?)
   2. find the entry with this authToken (most likely - the first one)
   3. remove
   4. serialize, save new history

   */
}

@end
