// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSCosmosDbIngestion.h"
#import "MSDataStore.h"
#import "MSServiceInternal.h"
#import "MSStorageIngestion.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDataStore <T : id <MSSerializableDocument>>() <MSServiceInternal>

/**
 * An token exchange url that is used to get resouce tokens.
 */
@property(nonatomic, copy) NSString *tokenExchangeUrl;

/**
 * An ingestion instance that is used to send a request for new token exchange service.
 */
@property(nonatomic, nullable) MSStorageIngestion *ingestion;

/**
 * An ingestion instance that is used to send a request to CosmosDb.
 */
@property(nonatomic, nullable) MSCosmosDbIngestion *cosmosHttpClient;

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
