// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSSerializableDocument.h"
#import "MSServiceAbstract.h"

@class MSDataSourceError;
@class MSDocumentWrapper<T : id<MSSerializableDocument>>;
@class MSPaginatedDocuments<T : id<MSSerializableDocument>>;
@class MSReadOptions;
@class MSWriteOptions;

/**
 * App Data Storage service.
 */

NS_ASSUME_NONNULL_BEGIN

/**
 * Error domain for Storage.
 */
static NSString *const kMSDataStorageErrorDomain = @"MSDataStorageErrorDomain";

/**
 * User partition.
 * An authenticated user can read/write documents in this partition.
 */
static NSString *const MSDataStoreUserDocumentsPartition = @"user";

/**
 * Application partition.
 * Everyone can read documents in this partition.
 * Writes not allowed via the SDK.
 */
static NSString *const MSDataStoreAppDocumentsPartition = @"readonly";

/**
 * Time to live constants
 */
static int const MSDataStoreTimeToLiveInfinite = -1;
static int const MSDataStoreTimeToLiveNoCache = 0;
static int const MSDataStoreTimeToLiveDefault = 60 * 60;

@interface MSDataStore<T : id <MSSerializableDocument>> : MSServiceAbstract

typedef void (^MSDocumentWrapperCompletionHandler)(MSDocumentWrapper<T> *document);
typedef void (^MSPaginatedDocumentsCompletionHandler)(MSPaginatedDocuments<T> *documents);
typedef void (^MSDataSourceErrorCompletionHandler)(MSDataSourceError *error);

/**
 * Change The URL that will be used for getting token.
 *
 * @param tokenExchangeUrl The new URL.
 */
+ (void)setTokenExchangeUrl:(NSString *)tokenExchangeUrl;

/**
 * Read a document.
 * The document type (T) must be JSON deserializable.
 *
 * @param partition The CosmosDB partition key.
 * @param documentId The CosmosDB document id.
 * @param documentType The object type of the document. Must conform to MSSerializableDocument protocol.
 * @param completionHandler Callback to accept downloaded document.
 */
+ (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

/**
 * Read a document.
 *
 * @param partition The CosmosDB partition key.
 * @param documentId The CosmosDB document id.
 * @param documentType The object type of the document. Must conform to MSSerializableDocument protocol.
 * @param readOptions Options for reading and storing the document.
 * @param completionHandler Callback to accept document.
 */
+ (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
              readOptions:(MSReadOptions *_Nullable)readOptions
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

/**
 * Retrieve a paginated list of the documents in a partition.
 *
 * @param partition The CosmosDB partition key.
 * @param documentType The object type of the documents in the partition. Must conform to MSSerializableDocument protocol.
 * @param completionHandler Callback to accept documents.
 */
+ (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

/**
 * Retrieve a paginated list of the documents in a partition.
 *
 * @param partition The CosmosDB partition key.
 * @param documentType The object type of the documents in the partition. Must conform to MSSerializableDocument protocol.
 * @param readOptions Options for reading and storing the documents.
 * @param completionHandler Callback to accept documents.
 */
+ (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
              readOptions:(MSReadOptions *_Nullable)readOptions
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

/**
 * Create a document in CosmosDB.
 *
 * @param partition The CosmosDB partition key.
 * @param documentId The CosmosDB document id.
 * @param document The document to be stored in CosmosDB. Must conform to MSSerializableDocument protocol.
 * @param completionHandler Callback to accept document.
 */
+ (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(T)document
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

/**
 * Create a document in CosmosDB.
 *
 * @param partition The CosmosDB partition key.
 * @param documentId The CosmosDB document id.
 * @param document The document to be stored in CosmosDB. Must conform to MSSerializableDocument protocol.
 * @param writeOptions Options for writing and storing the document.
 * @param completionHandler Callback to accept document.
 */
+ (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(T)document
               writeOptions:(MSWriteOptions *_Nullable)writeOptions
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

/**
 * Replace a document in CosmosDB.
 *
 * @param partition The CosmosDB partition key.
 * @param documentId The CosmosDB document id.
 * @param document The document to be stored in CosmosDB. Must conform to MSSerializableDocument protocol.
 * @param completionHandler Callback to accept document.
 */
+ (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(T)document
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

/**
 * Replace a document in CosmosDB.
 *
 * @param partition The CosmosDB partition key.
 * @param documentId The CosmosDB document id.
 * @param document The document to be stored in CosmosDB. Must conform to MSSerializableDocument protocol.
 * @param writeOptions Options for writing and storing the document.
 * @param completionHandler Callback to accept document.
 */
+ (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(T)document
                writeOptions:(MSWriteOptions *_Nullable)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

/**
 * Delete a document from CosmosDB.
 *
 * @param partition The CosmosDB partition key.
 * @param documentId The CosmosDB document id.
 * @param completionHandler Callback to accept any errors.
 */
+ (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                  completionHandler:(MSDataSourceErrorCompletionHandler)completionHandler;

/**
 * Delete a document from CosmosDB.
 *
 * @param partition The CosmosDB partition key.
 * @param documentId The CosmosDB document id.
 * @param writeOptions Options for deleting the document.
 * @param completionHandler Callback to accept any errors.
 */
+ (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                       writeOptions:(MSWriteOptions *_Nullable)writeOptions
                  completionHandler:(MSDataSourceErrorCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
