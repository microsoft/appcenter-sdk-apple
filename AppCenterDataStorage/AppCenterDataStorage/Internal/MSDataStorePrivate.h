// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContextDelegate.h"
#import "MSServiceInternal.h"
#import "MS_Reachability.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Base URL for HTTP for token exchange.
 */
static NSString *const kMSDefaultApiUrl = @"https://tokens.appcenter.ms/v0.1";

@interface MSDataStore () <MSAuthTokenContextDelegate>

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

/**
 * Dispatch queue to execute local storage operations with.
 */
@property(nonatomic) dispatch_queue_t dispatchQueue;

/**
 * Retrieve a paginated list of the documents in a partition.
 *
 * @param partition The CosmosDB partition key.
 * @param documentType The object type of the documents in the partition. Must conform to MSSerializableDocument protocol.
 * @param continuationToken The continuation token for the page to retrieve (if any).
 * @param completionHandler Callback to accept documents.
 */
- (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
        continuationToken:(NSString *_Nullable)continuationToken
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

@end

NS_ASSUME_NONNULL_END
