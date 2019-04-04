// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDataStore.h"
#import "MSServiceInternal.h"

@protocol MSDocumentStore;

NS_ASSUME_NONNULL_BEGIN

@protocol MSHttpClientProtocol;

@interface MSDataStore <T : id <MSSerializableDocument>>() <MSServiceInternal>

/**
 * A token exchange url that is used to get resource tokens.
 */
@property(nonatomic, copy) NSURL *tokenExchangeUrl;

/**
 * A local store instance that is used to manage application and user level documents.
 */
@property(nonatomic) id<MSDocumentStore> documentStore;

/**
 * An ingestion instance that is used to send a request to CosmosDb.
 * HTTP client.
 */
@property(nonatomic, nullable) id<MSHttpClientProtocol> httpClient;

/**
 * Retrieve a paginated list of the documents in a partition.
 *
 * @param partition The CosmosDB partition key.
 * @param documentType The object type of the documents in the partition. Must conform to MSSerializableDocument protocol.
 * @param readOptions Options for reading and storing the documents.
 * @param continuationToken The continuation token for the page to retrieve (if any).
 * @param completionHandler Callback to accept documents.
 */
+ (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
              readOptions:(MSReadOptions *_Nullable)readOptions
        continuationToken:(NSString *_Nullable)continuationToken
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
