// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenInfo.h"
#import "MSIdentityPrivate.h"
#import "MSIdentityConstants.h"
#import "MSKeychainAuthTokenStorage.h"
#import "MSKeychainUtil.h"
#import "MSLogger.h"
#import "MSUtility.h"
#import "MSAuthTokenStoryEntry.h"

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

  //Read token array from storage.
  NSMutableArray *tokenArray = [MSKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];
  if ([tokenArray count] == 0) return nil;
  else {
    NSDate *firstDate = tokenArray[1];
    NSDate *lastDate = [tokenArray count] > 1 ? [tokenArray[2] timestampAsDate] : nil;
    return [[MSAuthTokenInfo alloc] initWithAuthToken:[tokenArray[1] authToken] andStartTime:firstDate andEndTime:lastDate];
  }
}

- (void)saveAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId {
  @synchronized (self) {

    //Read token array from storage.
    NSMutableArray *tokenArray = [MSKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];
    if ([tokenArray count] == 0) {

      //Add nil token if the entire story is empty.
      MSAuthTokenStoryEntry *newAuthToken = [[MSAuthTokenStoryEntry alloc] initWithAuthToken:nil];
      [tokenArray addObject:newAuthToken];
    }
    if ([[tokenArray lastObject] authToken] != authToken) {

      //If new token differs from the last token of array - add it to array.
      MSAuthTokenStoryEntry *newAuthToken = [[MSAuthTokenStoryEntry alloc] initWithAuthToken:authToken];
      [tokenArray addObject:newAuthToken];
    }

    //Cap array size at max avaliable size const (deleting from beginning).
    if ([tokenArray count] > kMSIdentityMaxAuthTokenArraySize) {
      [tokenArray removeObjectsFromIndices:1 numIndices:kMSIdentityMaxAuthTokenArraySize - [tokenArray count]];
    }

    //Save new array.
    [MSKeychainUtil storeArray:tokenArray forKey:kMSIdentityAuthTokenArrayKey];

    //TODO: Determine whether code is redundant and delete if necessary.
    /*
     if (authToken) {
      [self addTokenToStoryOnSignIn:authToken];
    } else {
      [self addEmptyTokenToStoryOnSignOut];
    }
     */
    //Write token to storage.
    if ([MSKeychainUtil storeString:(NSString *) authToken forKey:kMSIdentityAuthTokenKey]) {
      MSLogDebug([MSIdentity logTag], @"Saved new auth token in keychain.");
    } else {
      MSLogWarning([MSIdentity logTag], @"Failed to save new auth token in keychain.");
    }

    if (authToken && accountId) {
      [MS_USER_DEFAULTS setObject:(NSString *) accountId forKey:kMSIdentityMSALAccountHomeAccountKey];

    } else {
      [MS_USER_DEFAULTS removeObjectForKey:kMSIdentityMSALAccountHomeAccountKey];
    }
  }
}

- (void)removeAuthToken:(nullable NSString *)authToken {
  @synchronized (self) {

    //Read token array from storage.
    NSMutableArray *tokenArray = [MSKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];
    for (NSUInteger i = [tokenArray count]; i > 0; i--) {
      if ([tokenArray[i] authToken] == authToken) {
        [tokenArray removeObjectAtIndex:i];
        break;
      }
    }

    //Save new array.
    [MSKeychainUtil storeArray:tokenArray forKey:kMSIdentityAuthTokenArrayKey];
  }
}

@end
