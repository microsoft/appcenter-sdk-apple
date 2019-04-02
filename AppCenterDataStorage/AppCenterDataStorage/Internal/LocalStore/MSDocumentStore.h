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
 * @return BOOL Indicates if the document was saved successfully.
 */
- (BOOL)createWithPartition:(NSString *)partition document:(MSDocumentWrapper *)document writeOptions:(MSWriteOptions *)writeOptions;

/**
 * Delete table.
 *
 * @param accountId The logged in user id.
 *
 * @return BOOL Indicates if the table was deleted successfully.
 */
- (BOOL)deleteUserStorageWithAccountId:(NSString *)accountId;

/**
 * Create table.
 *
 * @param accountId The logged in user id.
 *
 * @return BOOL Indicates if the table was created successfully.
 */
- (NSUInteger)createUserStorageWithAccountId:(NSString *)accountId;

@end

NS_ASSUME_NONNULL_END
