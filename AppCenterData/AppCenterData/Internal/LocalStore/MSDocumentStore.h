// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSDocumentWrapper;
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
 * Get all pending operations.
 *
 * @param token CosmosDB token.
 *
 * @return List of all pending operations.
 */
- (NSArray<MSPendingOperation *> *)pendingOperationsWithToken:(MSTokenResult *)token;

@end

NS_ASSUME_NONNULL_END
