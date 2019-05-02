// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSHttpClientProtocol.h"
#import "MSSerializableDocument.h"

NS_ASSUME_NONNULL_BEGIN

@class MSDataError;
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
 * @param document Document object.
 * @param additionalHeaders Additional http headers.
 * @param additionalUrlPath Additional url path appended to the existing path.
 * @param completionHandler Completion handler callback.
 */
+ (void)performCosmosDbAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                                        tokenResult:(MSTokenResult *)tokenResult
                                         documentId:(NSString *_Nullable)documentId
                                         httpMethod:(NSString *)httpMethod
                                           document:(id<MSSerializableDocument> _Nullable)document
                                  additionalHeaders:(NSDictionary *_Nullable)additionalHeaders
                                  additionalUrlPath:(NSString *_Nullable)additionalUrlPath
                                  completionHandler:(MSHttpRequestCompletionHandler)completionHandler;

/**
 * Build and return a rich error object for a CosmosDB HTTP response.
 * The error exposes the HTTP status code in the user info dictionary (`kMSCosmosDbHttpCodeKey`) as well as the error
 * (`NSUnderlyingErrorKey`).
 *
 * @param response The HTTP response (if any).
 * @param underlyingError The underlying error (if any).
 *
 * @return A rich error object.
 */
+ (MSDataError *)cosmosDbErrorWithResponse:(NSHTTPURLResponse *_Nullable)response underlyingError:(NSError *_Nullable)underlyingError;

@end

NS_ASSUME_NONNULL_END
