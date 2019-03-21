// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^MSCosmosDbCompletionHandler)(NSData *_Nullable data, NSError *error);
typedef void (^MSCosmosDbCompletionHandlerWithHeaders)(NSData *_Nullable data, NSDictionary *headers, NSError *error);

@class MSCosmosDbIngestion;
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
 * @param additionalHeaders Additional http headers.
 * @param completionHandler Completion handler callback.
 */
+ (void)performCosmosDbAsyncOperationWithHttpClient:(MSCosmosDbIngestion *)httpClient
                                        tokenResult:(MSTokenResult *)tokenResult
                                         documentId:(NSString *)documentId
                                         httpMethod:(NSString *)httpMethod
                                               body:(NSData *_Nullable)body
                                  additionalHeaders:(NSDictionary *_Nullable)additionalHeaders
                                  completionHandler:(MSCosmosDbCompletionHandler)completionHandler;

/**
 * Call CosmosDb Api and perform db actions(read, write, delete, list, etc).
 *
 * @param httpClient Http client to call perform http calls .
 * @param tokenResult Token result object containing token value used to call CosmosDb Api.
 * @param documentId Document Id.
 * @param httpMethod Http method.
 * @param body Http body.
 * @param additionalHeaders Additional http headers.
 * @param completionHandlerWithHeaders Completion handler callback.
 */
+ (void)performCosmosDbAsyncOperationWithHttpClient:(MSCosmosDbIngestion *)httpClient
                                        tokenResult:(MSTokenResult *)tokenResult
                                         documentId:(NSString *)documentId
                                         httpMethod:(NSString *)httpMethod
                                               body:(NSData *_Nullable)body
                                  additionalHeaders:(NSDictionary *_Nullable)additionalHeaders
                       completionHandlerWithHeaders:(MSCosmosDbCompletionHandlerWithHeaders)completionHandlerWithHeaders;

@end

NS_ASSUME_NONNULL_END
