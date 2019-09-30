// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDBDocumentStore.h"
#import "MSData.h"
#import "MSDataOperationProxy.h"
#import "MSDocumentStore.h"
#import "MSServiceInternal.h"
#import "MS_Reachability.h"

@protocol MSDocumentStore;

NS_ASSUME_NONNULL_BEGIN

@protocol MSHttpClientProtocol;

@interface MSData () <MSServiceInternal>

/**
 * A token exchange url that is used to get resource tokens.
 */
@property(nonatomic, copy) NSURL *tokenExchangeUrl;

/**
 * An HTTP client instance that is used to send a request to CosmosDb with default retry logic enabled.
 */
@property(nonatomic) id<MSHttpClientProtocol> httpClientWithRetrier;

/**
 * An HTTP client  instance that is used to send a request to CosmosDb with no retry logic enabled.
 */
@property(nonatomic) id<MSHttpClientProtocol> httpClientNoRetrier;

/**
 * Network state helper.
 */
@property(nonatomic) MS_Reachability *reachability;

/**
 * Data operation proxy instance (for offline/online scenarios).
 */
@property(nonatomic) MSDataOperationProxy *dataOperationProxy;

/**
 * Retrieve a paginated list of the documents in a partition.
 *
 * @param documentType The object type of the documents in the partition. Must conform to MSSerializableDocument protocol.
 * @param partition The CosmosDB partition key.
 * @param readOptions Options for reading and storing the document.
 * @param continuationToken The continuation token for the page to retrieve (if any).
 * @param completionHandler Callback to accept documents.
 */
+ (void)listDocumentsWithType:(Class)documentType
                    partition:(NSString *)partition
                  readOptions:(MSReadOptions *_Nullable)readOptions
            continuationToken:(NSString *_Nullable)continuationToken
            completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
