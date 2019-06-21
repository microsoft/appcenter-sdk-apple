// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContextDelegate.h"
#import "MSRemoteOperationDelegate.h"
#import "MSServiceInternal.h"
#import "MS_Reachability.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Base URL for HTTP for token exchange.
 */
static NSString *const kMSDefaultApiUrl = @"https://tokens.appcenter.ms/v0.1";

@interface MSData () <MSAuthTokenContextDelegate>

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

/**
 * Dispatch queue to execute local storage operations with.
 */
@property(nonatomic) dispatch_queue_t dispatchQueue;

/**
 * Set of outgoing pending operation ids.
 */
@property(nonatomic, copy) NSMutableSet<NSString *> *outgoingPendingOperations;

/**
 * Remote operation delegate.
 */
@property(nonatomic, weak) id<MSRemoteOperationDelegate> remoteOperationDelegate;

/**
 * Retrieve a paginated list of the documents in a partition.
 *
 * @param documentType The object type of the documents in the partition. Must conform to MSSerializableDocument protocol.
 * @param partition The CosmosDB partition key.
 * @param readOptions Options for reading and storing the document.
 * @param continuationToken The continuation token for the page to retrieve (if any).
 * @param completionHandler Callback to accept documents.
 */
- (void)listDocumentsWithType:(Class)documentType
                    partition:(NSString *)partition
                  readOptions:(MSReadOptions *_Nullable)readOptions
            continuationToken:(nullable NSString *)continuationToken
            completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

/**
 * Perform Cosmos DB operation.
 *
 * @param partition The CosmosDB partition key.
 * @param documentId The identifier of a document.
 * @param httpMethod Http method.
 * @param document Document object.
 * @param additionalHeaders Additional http headers.
 * @param additionalUrlPath Additional url path appended to the url.
 * @param completionHandler Completion handler callback.
 */
- (void)performCosmosDbOperationWithPartition:(NSString *)partition
                                   documentId:(NSString *_Nullable)documentId
                                   httpMethod:(NSString *)httpMethod
                                     document:(id<MSSerializableDocument> _Nullable)document
                            additionalHeaders:(NSDictionary *_Nullable)additionalHeaders
                            additionalUrlPath:(NSString *_Nullable)additionalUrlPath
                            completionHandler:(MSHttpRequestCompletionHandler)completionHandler;

/**
 * Synchronize the document from CosmosDB with local cache.
 *
 * @param token The CosmosDB auth token.
 * @param documentId The identifier of a document.
 * @param documentWrapper Document wrapper object.
 * @param pendingOperation Pending operation.
 * @param operationExpirationTime operation expiration time.
 */
- (void)synchronizeLocalCacheWithCosmosDbWithToken:(MSTokenResult *)token
                                        documentId:(NSString *)documentId
                                   documentWrapper:(MSDocumentWrapper *)documentWrapper
                                  pendingOperation:(NSString *)pendingOperation
                           operationExpirationTime:(NSInteger)operationExpirationTime;

/**
 * Process pending operations and sync with CosmosDb.
 */
- (void)processPendingOperations;

@end

NS_ASSUME_NONNULL_END
