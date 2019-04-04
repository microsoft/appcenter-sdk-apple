// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSWriteOptions;
@class MSDocumentWrapper;

NS_ASSUME_NONNULL_BEGIN

@protocol MSDocumentStore <NSObject>

/**
 * Create an entry in the cache.
 *
 * @param partition The logged in user id.
 * @param document Document object to cache
 * @param writeOptions Gives the Time To Live to be set on the cached document
 *
 * @return YES if the document was saved successfully, NO otherwise.
 */
- (BOOL)createWithPartition:(NSString *)partition document:(MSDocumentWrapper *)document writeOptions:(MSWriteOptions *)writeOptions;

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
