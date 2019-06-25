// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSSerializableDocument.h"
#import "MSServiceAbstract.h"

@class MSDataError;
@class MSDocumentWrapper;
@class MSPaginatedDocuments;
@class MSReadOptions;
@class MSWriteOptions;

@protocol MSRemoteOperationDelegate;

/**
 * App Data service.
 */

NS_ASSUME_NONNULL_BEGIN

/**
 * User partition.
 * An authenticated user can read/write documents in this partition.
 */
static NSString *const kMSDataUserDocumentsPartition = @"user";

/**
 * Application partition.
 * Everyone can read documents in this partition.
 * Writes not allowed via the SDK.
 */
static NSString *const kMSDataAppDocumentsPartition = @"readonly";

/**
 * No expiration on cache.
 */
static int const kMSDataTimeToLiveInfinite = -1;

/**
 * Do not cache.
 */
static int const kMSDataTimeToLiveNoCache = 0;

/**
 * Default expiration on cache.
 */
static int const kMSDataTimeToLiveDefault = kMSDataTimeToLiveInfinite;

@interface MSData : MSServiceAbstract

typedef void (^MSDocumentWrapperCompletionHandler)(MSDocumentWrapper *document);
typedef void (^MSPaginatedDocumentsCompletionHandler)(MSPaginatedDocuments *documents);

/**
 * Change The URL that will be used for getting token.
 *
 * @param tokenExchangeUrl The new URL.
 */
+ (void)setTokenExchangeUrl:(NSString *)tokenExchangeUrl;

/**
 * Set the remote operation delegate which gets called when the device is back online
 * and the pending operations are processed.
 *
 * @param delegate A remote operation delegate.
 */
+ (void)setRemoteOperationDelegate:(nullable id<MSRemoteOperationDelegate>)delegate;

/**
 * Read a document.
 * The document type (id<MSSerializableDocument>) must be JSON deserializable.
 *
 * @param documentID The CosmosDB document ID.
 * @param documentType The object type of the document. Must conform to MSSerializableDocument protocol.
 * @param partition The CosmosDB partition key.
 * @param completionHandler Callback to accept downloaded document.
 */
+ (void)readDocumentWithID:(NSString *)documentID
              documentType:(Class)documentType
                 partition:(NSString *)partition
         completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler // clang-format off
NS_SWIFT_NAME(read(withDocumentID:documentType:partition:completionHandler:));
// clang-format on

/**
 * Read a document.
 *
 * @param documentID The CosmosDB document ID.
 * @param documentType The object type of the document. Must conform to MSSerializableDocument protocol.
 * @param partition The CosmosDB partition key.
 * @param readOptions Options for reading and storing the document.
 * @param completionHandler Callback to accept document.
 */
+ (void)readDocumentWithID:(NSString *)documentID
              documentType:(Class)documentType
                 partition:(NSString *)partition
               readOptions:(MSReadOptions *_Nullable)readOptions
         completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler // clang-format off
NS_SWIFT_NAME(read(withDocumentID:documentType:partition:readOptions:completionHandler:));
// clang-format on

/**
 * Retrieve a paginated list of the documents in a partition.
 *
 * @param documentType The object type of the documents in the partition. Must conform to MSSerializableDocument protocol.
 * @param partition The CosmosDB partition key.
 * @param completionHandler Callback to accept documents.
 */
+ (void)listDocumentsWithType:(Class)documentType
                    partition:(NSString *)partition
            completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

/**
 * Retrieve a paginated list of the documents in a partition.
 *
 * @param documentType The object type of the documents in the partition. Must conform to MSSerializableDocument protocol.
 * @param partition The CosmosDB partition key.
 * @param readOptions Options for reading and storing the document.
 * @param completionHandler Callback to accept documents.
 */
+ (void)listDocumentsWithType:(Class)documentType
                    partition:(NSString *)partition
                  readOptions:(MSReadOptions *_Nullable)readOptions
            completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

/**
 * Create a document in CosmosDB.
 *
 * @param documentID The CosmosDB document ID.
 * @param document The document to be stored in CosmosDB. Must conform to MSSerializableDocument protocol.
 * @param partition The CosmosDB partition key.
 * @param completionHandler Callback to accept document.
 */
+ (void)createDocumentWithID:(NSString *)documentID
                    document:(id<MSSerializableDocument>)document
                   partition:(NSString *)partition
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler // clang-format off
NS_SWIFT_NAME(create(withDocumentID:document:partition:completionHandler:));
// clang-format on

/**
 * Create a document in CosmosDB.
 *
 * @param documentID The CosmosDB document ID.
 * @param document The document to be stored in CosmosDB. Must conform to MSSerializableDocument protocol.
 * @param partition The CosmosDB partition key.
 * @param writeOptions Options for writing and storing the document.
 * @param completionHandler Callback to accept document.
 */
+ (void)createDocumentWithID:(NSString *)documentID
                    document:(id<MSSerializableDocument>)document
                   partition:(NSString *)partition
                writeOptions:(MSWriteOptions *_Nullable)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler // clang-format off
NS_SWIFT_NAME(create(withDocumentID:document:partition:writeOptions:completionHandler:));
// clang-format on

/**
 * Replace a document in CosmosDB.
 *
 * @param documentID The CosmosDB document ID.
 * @param document The document to be stored in CosmosDB. Must conform to MSSerializableDocument protocol.
 * @param partition The CosmosDB partition key.
 * @param completionHandler Callback to accept document.
 */
+ (void)replaceDocumentWithID:(NSString *)documentID
                     document:(id<MSSerializableDocument>)document
                    partition:(NSString *)partition
            completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler // clang-format off
NS_SWIFT_NAME(replace(withDocumentID:document:partition:completionHandler:));
// clang-format on

/**
 * Replace a document in CosmosDB.
 *
 * @param documentID The CosmosDB document ID.
 * @param document The document to be stored in CosmosDB. Must conform to MSSerializableDocument protocol.
 * @param partition The CosmosDB partition key
 * @param writeOptions Options for writing and storing the document.
 * @param completionHandler Callback to accept document.
 */
+ (void)replaceDocumentWithID:(NSString *)documentID
                     document:(id<MSSerializableDocument>)document
                    partition:(NSString *)partition
                 writeOptions:(MSWriteOptions *_Nullable)writeOptions
            completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler // clang-format off
NS_SWIFT_NAME(replace(withDocumentID:document:partition:writeOptions:completionHandler:));
// clang-format on

/**
 * Delete a document from CosmosDB.
 *
 * @param documentID The CosmosDB document ID.
 * @param partition The CosmosDB partition key.
 * @param completionHandler Callback to accept any errors.
 */
+ (void)deleteDocumentWithID:(NSString *)documentID
                   partition:(NSString *)partition
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler // clang-format off
NS_SWIFT_NAME(delete(withDocumentID:partition:completionHandler:));
// clang-format on

/**
 * Delete a document from CosmosDB.
 *
 * @param documentID The CosmosDB document ID.
 * @param partition The CosmosDB partition key.
 * @param writeOptions Options for deleting the document.
 * @param completionHandler Callback to accept any errors.
 */
+ (void)deleteDocumentWithID:(NSString *)documentID
                   partition:(NSString *)partition
                writeOptions:(MSWriteOptions *_Nullable)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler // clang-format off
    NS_SWIFT_NAME(delete(withDocumentID:partition:writeOptions:completionHandler:));
// clang-format on

@end

NS_ASSUME_NONNULL_END
