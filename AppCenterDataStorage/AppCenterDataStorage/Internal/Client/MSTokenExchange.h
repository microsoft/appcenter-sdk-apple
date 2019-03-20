// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MSTokensResponse;
@class MSStorageIngestion;

typedef void (^MSGetTokenAsyncCompletionHandler)(MSTokensResponse *tokenResponses, NSError *_Nullable error);

/**
 * This class retrieves and caches Cosmosdb access token.
 */
@interface MSTokenExchange : NSObject

/**
 * Get token from token exchange.
 *
 * @param httpClient http client.
 * @param partition cosmosdb partition.
 * @param completionHandler callback that gets the token.
 *
 */
+ (void)performDbTokenAsyncOperationWithHttpClient:(MSStorageIngestion *)httpClient
                                         partition:(NSString *)partition
                                 completionHandler:(MSGetTokenAsyncCompletionHandler _Nonnull)completionHandler;

/*
 * When the user logs out, all the cached tokens are deleted.
 */
+ (void)removeAllCachedTokens;

@end

NS_ASSUME_NONNULL_END
