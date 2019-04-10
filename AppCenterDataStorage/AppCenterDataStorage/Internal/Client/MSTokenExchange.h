// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDataStorageConstants.h"
#import "MSTokenResult.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSHttpClientProtocol;
@class MSTokensResponse;

typedef void (^MSGetTokenAsyncCompletionHandler)(MSTokensResponse *tokenResponses, NSError *_Nullable error);

/**
 * This class retrieves and caches CosmosDB access token.
 */
@interface MSTokenExchange : NSObject

/**
 * Gets token from token exchange.
 *
 * @param httpClient The HTTP client.
 * @param tokenExchangeUrl The API URL to exchange token.
 * @param appSecret The application secret.
 * @param partition The CosmosDB partition.
 * @param completionHandler A callback that is invoked when the token is acquired.
 */
+ (void)performDbTokenAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                                  tokenExchangeUrl:(NSURL *)tokenExchangeUrl
                                         appSecret:(NSString *)appSecret
                                         partition:(NSString *)partition
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

@end

NS_ASSUME_NONNULL_END
