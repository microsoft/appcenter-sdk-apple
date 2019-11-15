// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSTokenExchange.h"
#import "AppCenter+Internal.h"
#import "MSAuthTokenContext.h"
#import "MSConstants+Internal.h"
#import "MSDataConstants.h"
#import "MSDataErrors.h"
#import "MSDataInternal.h"
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
                                      reachability:(MS_Reachability *)reachability
                                 completionHandler:(MSGetTokenAsyncCompletionHandler)completionHandler {
  if (![MSTokenExchange isValidPartitionName:partition]) {
    MSLogError([MSData logTag], @"Can't perform token exchange because partition name %@ is invalid.", partition);
    NSError *error =
        [[NSError alloc] initWithDomain:kMSACDataErrorDomain
                                   code:MSACDataErrorInvalidPartition
                               userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Invalid partition name %@", partition]}];
    completionHandler([[MSTokensResponse alloc] initWithTokens:nil], error);
    return;
  }

  // Get the cached token if it is saved.
  MSTokenResult *cachedToken = [MSTokenExchange retrieveCachedTokenForPartition:partition includeExpiredToken:includeExpiredToken];
  NSURL *sendUrl = [tokenExchangeUrl URLByAppendingPathComponent:kMSGetTokenPath];

  // Get a fresh token from the token exchange service if the token is not cached or has expired and the nework is connected.
  if (!cachedToken) {
    if ([reachability currentReachabilityStatus] != NotReachable) {
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
            MSLogVerbose([MSData logTag], @"Get token callback status code: %td", response.statusCode);

            // Token exchange failed to give back a token.
            if (error) {
              MSLogError([MSData logTag], @"Get on DB Token had an error with code: %td, description: %@", error.code,
                         error.localizedDescription);
              completionHandler([[MSTokensResponse alloc] initWithTokens:nil], error);
              return;
            }

            // Token store returned non-200 response code.
            if (response.statusCode != MSHTTPCodesNo200OK) {
              MSLogError([MSData logTag], @"The token store returned %ld", (long)response.statusCode);
              completionHandler([[MSTokensResponse alloc] initWithTokens:nil],
                                [[NSError alloc] initWithDomain:kMSACDataErrorDomain
                                                           code:MSACDataErrorHTTPError
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
              MSLogError([MSData logTag], @"Can't deserialize tokens with error: %@", [tokenResponsejsonError description]);
              NSError *serializeError = [[NSError alloc]
                  initWithDomain:kMSACDataErrorDomain
                            code:MSACDataErrorJSONSerializationFailed
                        userInfo:@{
                          NSLocalizedDescriptionKey :
                              [NSString stringWithFormat:@"Can't deserialize tokens with error: %@", [tokenResponsejsonError description]]
                        }];
              completionHandler([[MSTokensResponse alloc] initWithTokens:nil], serializeError);
              return;
            }
            if ([(NSArray *)jsonDictionary[kMSTokens] count] == 0) {
              MSLogError([MSData logTag], @"Invalid token exchange service response.");
              NSError *errorResponse = [[NSError alloc]
                  initWithDomain:kMSACDataErrorDomain
                            code:MSACDataErrorInvalidTokenExchangeResponse
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
              MSLogError([MSData logTag], @"Token result had a status of %@", tokenResult.status);
              NSError *statusError = [[NSError alloc]
                  initWithDomain:kMSACDataErrorDomain
                            code:MSACDataErrorHTTPError
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
      MSLogError([MSData logTag], @"No cached token result found, and device is offline.");
      NSError *error =
          [[NSError alloc] initWithDomain:kMSACDataErrorDomain
                                     code:MSACDataErrorUnableToGetToken
                                 userInfo:@{NSLocalizedDescriptionKey : @"No cached token result found, and device is offline."}];
      completionHandler([[MSTokensResponse alloc] initWithTokens:nil], error);
      return;
    }
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
    MSLogError([MSData logTag], @"Can't save the token to keychain because token is nil.");
  } else if (!tokenResult.partition) {
    MSLogError([MSData logTag], @"Can't save the token in keychain because partitionKey is nil.");
  } else {
    BOOL success = [MSKeychainUtil storeString:tokenString forKey:[MSTokenExchange tokenKeyNameForPartition:tokenResult.partition]];
    if (success) {
      MSLogDebug([MSData logTag], @"Saved token in keychain for the partitionKey : %@.", tokenResult.partition);
    } else {
      MSLogError([MSData logTag], @"Failed to save the token in keychain for the partitionKey : %@.", tokenResult.partition);
    }
  }
}

+ (MSTokenResult *_Nullable)retrieveCachedTokenForPartition:(NSString *)partition includeExpiredToken:(BOOL)includeExpiredToken {
  if (partition) {
    NSString *tokenString = [MSKeychainUtil stringForKey:[MSTokenExchange tokenKeyNameForPartition:partition] withStatusCode:nil];
    if (tokenString) {
      MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithString:tokenString];
      NSDate *currentUTCDate = [NSDate date];
      NSDate *tokenExpireDate = [MSUtility dateFromISO8601:tokenResult.expiresOn];
      if ([currentUTCDate laterDate:tokenExpireDate] == currentUTCDate) {
        MSLogWarning([MSData logTag], @"The token in the cache has expired for the partition : %@.", partition);
        if (includeExpiredToken) {
          return tokenResult;
        }
        return nil;
      }
      MSLogDebug([MSData logTag], @"Retrieved token from keychain for the partition : %@.", partition);
      return tokenResult;
    }
    MSLogWarning([MSData logTag], @"Failed to retrieve token from keychain or none was found for the partition : %@.", partition);
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
    MSLogDebug([MSData logTag], @"Removed all the tokens from keychain.");
  } else {
    MSLogWarning([MSData logTag], @"Failed to remove all of the tokens from keychain");
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
  if ([partitionName isEqualToString:kMSDataAppDocumentsPartition]) {
    return kMSStorageReadOnlyDbTokenKey;
  }
  return kMSStorageUserDbTokenKey;
}

+ (BOOL)isValidPartitionName:(NSString *)partitionName {
  return [partitionName isEqualToString:kMSDataAppDocumentsPartition] || [partitionName isEqualToString:kMSDataUserDocumentsPartition];
}

@end

NS_ASSUME_NONNULL_END
