// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpClientProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MSSerializableDocument;
@class MSTokenResult;

/**
 * This class performs CRUD operation in CosmosDb via an Http client.
 */
@interface MSCosmosDb : NSObject

/**
 * Call CosmosDb Api and perform db actions(read, write, delete, list, etc).
 *
 * @param httpClient Http client to call perform http calls .
 * @param tokenResult Token result object containing token value used to call CosmosDb Api.
 * @param documentId Document Id.
 * @param httpMethod Http method.
 * @param body Http body.
 * @param completionHandler Completion handler callback.
 */
+ (void)performCosmosDbAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                                        tokenResult:(MSTokenResult *)tokenResult
                                         documentId:(NSString *)documentId
                                         httpMethod:(NSString *)httpMethod
                                               body:(NSData *_Nullable)body
                                  completionHandler:(MSHttpRequestCompletionHandler)completionHandler;

/**
 * Call CosmosDb Api and perform db actions(read, write, delete, list, etc).
 *
 * @param httpClient Http client to call perform http calls .
 * @param tokenResult Token result object containing token value used to call CosmosDb Api.
 * @param documentId Document Id.
 * @param httpMethod Http method.
 * @param body Http body.
 * @param additionalHeaders Additional http headers.
 * @param offlineMode YES to simulate being offline and thus cause an http call failure, NO for a real call.
 * @param completionHandler Completion handler callback.
 */
+ (void)performCosmosDbAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                                        tokenResult:(MSTokenResult *)tokenResult
                                         documentId:(NSString *)documentId
                                         httpMethod:(NSString *)httpMethod
                                               body:(NSData *_Nullable)body
                                  additionalHeaders:(NSDictionary *_Nullable)additionalHeaders
                                        offlineMode:(BOOL)offlineMode
                                  completionHandler:(MSHttpRequestCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
