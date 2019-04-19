// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSTokenExchange.h"
#import "AppCenter+Internal.h"
#import "MSAuthTokenContext.h"
#import "MSConstants+Internal.h"
#import "MSDataStorageConstants.h"
#import "MSDataStoreErrors.h"
#import "MSDataStoreInternal.h"
#import "MSHttpClientProtocol.h"
#import "MSKeychainUtil.h"
#import "MSTokenResult.h"
#import "MSTokensResponse.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kMSPartitions = @"partitions";
static NSString *const kMSStorageReadOnlyDbTokenKey = @"MSStorageReadOnlyDbToken";
static NSString *const kMSStorageUserDbTokenKey = @"MSStorageUserDbToken";

/**
 * The API paths for cosmosDb token.
 */
static NSString *const kMSGetTokenPath = @"/data/tokens";

@implementation MSTokenExchange : NSObject

+ (void)performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                                  tokenExchangeUrl:(NSURL *)tokenExchangeUrl
                                         appSecret:(NSString *)appSecret
                                         partition:(NSString *)partition
                               includeExpiredToken:(BOOL)includeExpiredToken
                                    msreachability:(MS_Reachability *) __unused msreachability
                                 completionHandler:(MSGetTokenAsyncCompletionHandler)completionHandler {
  if (![MSTokenExchange isValidPartitionName:partition]) {
    MSLogError([MSDataStore logTag], @"Can't perform token exchange because partition name %@ is invalid.", partition);
    NSError *error =
        [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                   code:MSACDataStoreInvalidPartitionError
                               userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Invalid partition name %@", partition]}];
    completionHandler([[MSTokensResponse alloc] initWithTokens:nil], error);
    return;
  }

  // Get the cached token if it is saved.
  MSTokenResult *cachedToken = [MSTokenExchange retrieveCachedTokenForPartition:partition includeExpiredToken:includeExpiredToken];
  NSURL *sendUrl = [tokenExchangeUrl URLByAppendingPathComponent:kMSGetTokenPath];

  // Get a fresh token from the token exchange service if the token is not cached or has expired.
  if (!cachedToken) {

    // Serialize payload.
    NSError *jsonError;
    NSData *payloadData = [NSJSONSerialization dataWithJSONObject:@{kMSPartitions : @[ partition ]} options:0 error:&jsonError];

    // Call token exchange service.
    NSMutableDictionary *headers = [NSMutableDictionary new];
    headers[kMSHeaderContentTypeKey] = kMSAppCenterContentType;
    headers[kMSHeaderAppSecretKey] = appSecret;
    if ([[MSAuthTokenContext sharedInstance] authToken]) {
      headers[kMSAuthorizationHeaderKey] =
          [NSString stringWithFormat:kMSBearerTokenHeaderFormat, [[MSAuthTokenContext sharedInstance] authToken]];
    }
    [httpClient sendAsync:sendUrl
                   method:kMSHttpMethodPost
                  headers:headers
                     data:payloadData
        completionHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
          MSLogVerbose([MSDataStore logTag], @"Get token callback status code: %td", response.statusCode);

          // Token exchange failed to give back a token.
          if (error) {
            MSLogError([MSDataStore logTag], @"Get on DB Token had an error with code: %td, description: %@", error.code,
                       error.localizedDescription);
            completionHandler([[MSTokensResponse alloc] initWithTokens:nil], error);
            return;
          }

          // Token store returned non-200 response code.
          if (response.statusCode != MSHTTPCodesNo200OK) {
            MSLogError([MSDataStore logTag], @"The token store returned %ld", (long)response.statusCode);
            completionHandler([[MSTokensResponse alloc] initWithTokens:nil],
                              [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                                         code:MSACDataStoreErrorHTTPError
                                                     userInfo:@{
                                                       NSLocalizedDescriptionKey : [NSString
                                                           stringWithFormat:@"The token store returned %ld", (long)response.statusCode]
                                                     }]);
            return;
          }

          // Read tokens.
          NSError *tokenResponsejsonError;
          NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&tokenResponsejsonError];
          if (tokenResponsejsonError) {
            MSLogError([MSDataStore logTag], @"Can't deserialize tokens with error: %@", [tokenResponsejsonError description]);
            NSError *serializeError = [[NSError alloc]
                initWithDomain:kMSACDataStoreErrorDomain
                          code:MSACDataStoreErrorJSONSerializationFailed
                      userInfo:@{
                        NSLocalizedDescriptionKey :
                            [NSString stringWithFormat:@"Can't deserialize tokens with error: %@", [tokenResponsejsonError description]]
                      }];
            completionHandler([[MSTokensResponse alloc] initWithTokens:nil], serializeError);
            return;
          }
          if ([(NSArray *)jsonDictionary[kMSTokens] count] == 0) {
            MSLogError([MSDataStore logTag], @"Invalid token exchange service response.");
            NSError *errorResponse = [[NSError alloc]
                initWithDomain:kMSACDataStoreErrorDomain
                          code:MSACDataStoreInvalidTokenExchangeResponse
                      userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Invalid token exchange service response."]}];
            completionHandler([[MSTokensResponse alloc] initWithTokens:nil], errorResponse);
            return;
          }

          // Create token result object.
          MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:(NSDictionary *)jsonDictionary[kMSTokens][0]];

          // Create token response object.
          MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ tokenResult ]];

          // Token exchange did not get back an error but acquiring the token did not succeed either
          if (tokenResult && ![tokenResult.status isEqualToString:kMSTokenResultSucceed]) {
            MSLogError([MSDataStore logTag], @"Token result had a status of %@", tokenResult.status);
            NSError *statusError = [[NSError alloc]
                initWithDomain:kMSACDataStoreErrorDomain
                          code:MSACDataStoreErrorHTTPError
                      userInfo:@{
                        NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Token result had a status of %@", tokenResult.status]
                      }];
            completionHandler(tokensResponse, statusError);
            return;
          }

          // Cache the newly acquired token.
          [MSTokenExchange saveToken:tokenResult];
          completionHandler(tokensResponse, error);
        }];
  } else {
    completionHandler([[MSTokensResponse alloc] initWithTokens:@[ cachedToken ]], nil);
  }
}

/*
 * Cache the Cosmos DB token received from the token exchange service.
 * The token is stored in KeyChain
 */
+ (void)saveToken:(MSTokenResult *)tokenResult {
  NSString *tokenString = [tokenResult serializeToString];
  if (!tokenString) {
    MSLogError([MSDataStore logTag], @"Can't save the token to keychain because token is nil.");
  } else if (!tokenResult.partition) {
    MSLogError([MSDataStore logTag], @"Can't save the token in keychain because partitionKey is nil.");
  } else {
    BOOL success = [MSKeychainUtil storeString:tokenString forKey:[MSTokenExchange tokenKeyNameForPartition:tokenResult.partition]];
    if (success) {
      MSLogDebug([MSDataStore logTag], @"Saved token in keychain for the partitionKey : %@.", tokenResult.partition);
    } else {
      MSLogError([MSDataStore logTag], @"Failed to save the token in keychain for the partitionKey : %@.", tokenResult.partition);
    }
  }
}

+ (MSTokenResult *_Nullable)retrieveCachedTokenForPartition:(NSString *)partition includeExpiredToken:(BOOL)includeExpiredToken {
  if (partition) {
    NSString *tokenString = [MSKeychainUtil stringForKey:[MSTokenExchange tokenKeyNameForPartition:partition]];
    if (tokenString) {
      MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithString:tokenString];
      NSDate *currentUTCDate = [NSDate date];
      NSDate *tokenExpireDate = [MSUtility dateFromISO8601:tokenResult.expiresOn];
      if ([currentUTCDate laterDate:tokenExpireDate] == currentUTCDate) {
        MSLogWarning([MSDataStore logTag], @"The token in the cache has expired for the partition : %@.", partition);
        if (includeExpiredToken) {
          return tokenResult;
        }
        return nil;
      }
      MSLogDebug([MSDataStore logTag], @"Retrieved token from keychain for the partition : %@.", partition);
      return tokenResult;
    }
    MSLogWarning([MSDataStore logTag], @"Failed to retrieve token from keychain or none was found for the partition : %@.", partition);
  }
  return nil;
}

/*
 * When the user logs out, all the cached tokens are deleted
 */
+ (void)removeAllCachedTokens {
  NSString *readonlyTokenString = [MSKeychainUtil deleteStringForKey:kMSStorageReadOnlyDbTokenKey];
  NSString *userTokenString = [MSKeychainUtil deleteStringForKey:kMSStorageUserDbTokenKey];
  if (readonlyTokenString && userTokenString) {
    MSLogDebug([MSDataStore logTag], @"Removed all the tokens from keychain.");
  } else {
    MSLogWarning([MSDataStore logTag], @"Failed to remove all of the tokens from keychain");
  }
}

/*
 * Based on the partition name we have 2 different kinds of tokens that get issued
 * They get stored in KeyChain based on the partition
 * KeyNames :
 *     Readonly partion : MSStorageReadOnlyDbToken
 *       User partition : MSStorageUserDbToken
 */
+ (NSString *)tokenKeyNameForPartition:(NSString *)partitionName {
  if ([partitionName isEqualToString:kMSDataStoreAppDocumentsPartition]) {
    return kMSStorageReadOnlyDbTokenKey;
  }
  return kMSStorageUserDbTokenKey;
}

+ (BOOL)isValidPartitionName:(NSString *)partitionName {
  return [partitionName isEqualToString:kMSDataStoreAppDocumentsPartition] ||
         [partitionName isEqualToString:kMSDataStoreUserDocumentsPartition];
}

@end

NS_ASSUME_NONNULL_END
