// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSWriteOptions;
@class MSReadOptions;
@class MSDocumentWrapper;
@class MSTokenResult;

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
 * @param options The operation options (used to extract the device time-to-live information).
 *
 * @return YES if the document was saved successfully, NO otherwise.
 */
- (BOOL)upsertWithToken:(MSTokenResult *)token
        documentWrapper:(MSDocumentWrapper *)documentWrapper
              operation:(NSString *_Nullable)operation
                options:(MSBaseOptions *)options;

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
 * Delete all tables.
 */
- (void)deleteAllTables;

/**
 * Reads a document from the store.
 *
 * @param token CosmosDB token.
 * @param documentId Document ID.
 * @param documentType The document type to read.
 *
 * @return A document with the given ID.
 */
- (MSDocumentWrapper *)readWithToken:(MSTokenResult *)token documentId:(NSString *)documentId documentType:(Class)documentType;

@end

NS_ASSUME_NONNULL_END
