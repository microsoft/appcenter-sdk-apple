// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDataConstants.h"
#import "MSTokenResult.h"
#import "MS_Reachability.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSHttpClientProtocol;
@class MSTokensResponse;

typedef void (^MSGetTokenAsyncCompletionHandler)(MSTokensResponse *tokensResponse, NSError *_Nullable error);

/**
 * This class retrieves and caches CosmosDB access token.
 */
@interface MSTokenExchange : NSObject

/**
 * Gets token from token exchange.
 *
 * @param httpClient The http client.
 * @param tokenExchangeUrl API url to exchange token.
 * @param appSecret The application secret.
 * @param partition The CosmosDB partition.
 * @param includeExpiredToken The flag that indicates whether the method returns expired token from the cache or not.
 * @param reachability The reachability is used to check if the network is on or off.
 * @param completionHandler Callback that gets invoked when a token is retrieved.
 */
+ (void)performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                                  tokenExchangeUrl:(NSURL *)tokenExchangeUrl
                                         appSecret:(NSString *)appSecret
                                         partition:(NSString *)partition
                               includeExpiredToken:(BOOL)includeExpiredToken
                                      reachability:(MS_Reachability *)reachability
                                 completionHandler:(MSGetTokenAsyncCompletionHandler)completionHandler;

/**
 * Returns a cached (CosmosDB resource) token for a given partition name.
 *
 * @param partition The partition for which to return the token.
 * @param includeExpiredToken `YES` to return the cached token even if it is expired, `NO` to return `nil` if the token is expired.
 *
 * @return The cached token or `nil`.
 */
+ (MSTokenResult *_Nullable)retrieveCachedTokenForPartition:(NSString *)partition includeExpiredToken:(BOOL)includeExpiredToken;

/**
 * Deletes all cached tokens. This should be called when the user logs out.
 */
+ (void)removeAllCachedTokens;

/**
 * Validate the partition name passed to token exchange.
 * @param partition The partition name to be validated.
 *
 * @return The partition is valid or not.
 **/
+ (BOOL)isValidPartitionName:(NSString *)partition;

@end

NS_ASSUME_NONNULL_END
