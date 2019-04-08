// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSWriteOptions;
@class MSDocumentWrapper;

NS_ASSUME_NONNULL_BEGIN

@protocol MSDocumentStore <NSObject>

/**
 * Create or replace an entry in the store.
 *
 * @param partition Document partition.
 * @param documentWrapper Document wrapper object to store (may be `nil`, e.g. for a DELETE operation).
 * @param operation The operation store.
 * @param options The operation options (used to extract the device time-to-live information).
 *
 * @return YES if the document was saved successfully, NO otherwise.
 */
- (BOOL)upsertWithPartition:(NSString *)partition
                  accountId:(NSString *_Nullable)accountId
            documentWrapper:(MSDocumentWrapper *)documentWrapper
                  operation:(NSString *_Nullable)operation
                    options:(MSBaseOptions *)options;

/**
 * Delete an entry from the store.
 *
 * @param partition Document partition.
 * @param documentId Document ID.
 *
 * @return YES if the document was deleted successfully, NO otherwise.
 */
- (BOOL)deleteWithPartition:(NSString *)partition
                  accountId:(NSString *_Nullable)accountId
                 documentId:(NSString *)documentId;

/**
 * Delete table.
 *
 * @param accountId The logged in user id.
 *
 * @return YES if the table was deleted successfully, NO otherwise.
 */
- (BOOL)deleteUserStorageWithAccountId:(NSString *)accountId;

/**
 * Create a user table for the given account Id.
 *
 * @param accountId The logged in user id.
 *
 * @return YES if the table was created for this user successfully, NO otherwise.
 */
- (BOOL)createUserStorageWithAccountId:(NSString *)accountId;

@end

NS_ASSUME_NONNULL_END
