// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSBaseOptions.h"
#import "MSSerializableDocument.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDBDocumentStore : NSObject

/**
 * Create or replace an entry in the cache.
 *
 * @param partition The logged in user id.
 * @param document Document object to cache.
 * @param documentId The document ID.
 * @param lastUpdatedDate The last time the document was updated.
 * @param eTag The document's eTag.
 * @param operation The operation to perform on the document.
 * @param options Gives the Time To Live to be set on the cached document.
 *
 * @return YES if the document was saved successfully, NO otherwise.
 */
- (BOOL)upsertWithPartition:(NSString *)partition
                   document:(id<MSSerializableDocument>)document
                 documentId:(NSString *)documentId
            lastUpdatedDate:(NSDate *)lastUpdatedDate
                       eTag:(NSString *)eTag
                  operation:(NSString *_Nullable)operation
                    options:(MSBaseOptions *)options;

/**
 * Delete an entry from the cache.
 *
 * @param partition The logged in user id.
 * @param documentId The document ID.
 *
 * @return YES if the document was deleted successfully, NO otherwise.
 */
- (BOOL)deleteWithPartition:(NSString *)partition documentId:(NSString *)documentId;

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
