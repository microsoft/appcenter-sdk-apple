// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSDocumentWrapper;
@class MSPaginatedDocuments;
@class MSPendingOperation;
@class MSReadOptions;
@class MSTokenResult;
@class MSWriteOptions;

NS_ASSUME_NONNULL_BEGIN

@protocol MSDocumentStore <NSObject>

/**
 * Create a user table for the given account id.
 *
 * @param accountId The account id.
 *
 * @return YES if the table was created for this user successfully, NO otherwise.
 */
- (BOOL)createUserStorageWithAccountId:(NSString *)accountId;

/**
 * Create or replace an entry in the store.
 *
 * @param token CosmosDB token.
 * @param documentWrapper Document wrapper object to store.
 * @param operation The operation store.
 * @param deviceTimeToLive The device time to live (in seconds).
 *
 * @return YES if the document was saved successfully, NO otherwise.
 */
- (BOOL)upsertWithToken:(MSTokenResult *)token
        documentWrapper:(MSDocumentWrapper *)documentWrapper
              operation:(NSString *_Nullable)operation
       deviceTimeToLive:(NSInteger)deviceTimeToLive;

/**
 * Create or replace an entry in the store.
 *
 * @param token CosmosDB token.
 * @param documentWrapper Document wrapper object to store.
 * @param operation The operation store.
 * @param expirationTime Document expiration time.
 *
 * @return YES if the document was saved successfully, NO otherwise.
 */
- (BOOL)upsertWithToken:(MSTokenResult *)token
        documentWrapper:(MSDocumentWrapper *)documentWrapper
              operation:(NSString *_Nullable)operation
         expirationTime:(NSTimeInterval)expirationTime;

/**
 * Delete an entry from the store.
 *
 * @param token CosmosDB token.
 * @param documentId Document ID.
 *
 * @return YES if the document was deleted successfully, NO otherwise.
 */
- (BOOL)deleteWithToken:(MSTokenResult *)token documentId:(NSString *)documentId;

/**
 * Delete table for a given account id.
 *
 * @param accountId Account id.
 *
 * @return YES if the table was deleted successfully, NO otherwise.
 */
- (BOOL)deleteUserStorageWithAccountId:(NSString *)accountId;

/**
 * Reset database.
 */
- (void)resetDatabase;

/**
 * Read a document from the store and return it if it did not expired.
 *
 * @param token CosmosDB token.
 * @param documentId Document ID.
 * @param documentType The document type to read.
 *
 * @return A document object. The error property will be set of the document cannot be found or if it was found but expired.
 */
- (MSDocumentWrapper *)readWithToken:(MSTokenResult *)token documentId:(NSString *)documentId documentType:(Class)documentType;

/**
 * List all the documents from the store and return the list if not expired.
 *
 * @param token CosmosDB token.
 * @param partition The CosmosDB partition key.
 * @param documentType The document type to list.
 * @param baseOptions Options for listing and storing the documents.
 *
 * @return A MSPaginatedDocuments object. List of documents found in the local store for a particular partition.
 */
- (MSPaginatedDocuments *)listWithToken:(MSTokenResult *)token
                              partition:(NSString *)partition
                           documentType:(Class)documentType
                            baseOptions:(MSBaseOptions *_Nullable)baseOptions;

/**
 * Checks if there are any pending operations to be processed.
 *
 * @param partition The CosmosDB partition key.
 *
 * @return true if the partition has pending operations, else returns false.
 */
- (BOOL)hasPendingOperationsForPartition:(NSString *)partition;

/**
 * Update the local store given a current/new cached document.
 *
 * @param token The CosmosDB token.
 * @param currentCachedDocument The current cached document.
 * @param newCachedDocument The new document that should be cached.
 * @param deviceTimeToLive The device time to live for the new cached document.
 * @param operation The operation being intended (nil - READ, CREATE, UPDATE, DELETE).
 */
- (void)updateDocumentWithToken:(MSTokenResult *)token
          currentCachedDocument:(MSDocumentWrapper *)currentCachedDocument
              newCachedDocument:(MSDocumentWrapper *)newCachedDocument
               deviceTimeToLive:(NSInteger)deviceTimeToLive
                      operation:(NSString *_Nullable)operation;

/**
 * Update the local store given a list of remote documents.
 *
 * @param token The CosmosDB token.
 * @param documentList The remote list of documents that should be cached.
 * @param baseOptions Options for storing the remote list of documents.
 */
- (void)updateDocumentsWithToken:(MSTokenResult *)token
                 remoteDocuments:(MSPaginatedDocuments *)documentList
                     baseOptions:(MSBaseOptions *_Nullable)baseOptions;

/**
 * Get all pending operations.
 *
 * @param token CosmosDB token.
 *
 * @return List of all pending operations.
 */
- (NSArray<MSPendingOperation *> *)pendingOperationsWithToken:(MSTokenResult *)token;

@end

NS_ASSUME_NONNULL_END
