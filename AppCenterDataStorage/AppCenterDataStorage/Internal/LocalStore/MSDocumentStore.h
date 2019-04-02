// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSWriteOptions;
@class MSDocumentWrapper;

NS_ASSUME_NONNULL_BEGIN

@protocol MSDocumentStore <NSObject>

- (bool)createWithPartition:(NSString *)partition document:(MSDocumentWrapper *)document writeOptions:(MSWriteOptions *)options;

/**
 * Reads a document from local storage.
 *
 * @param documentId The identifier for the document.
 * @param partition The name of the partition that contains the document.
 * @param readOptions Options for reading the document.
 *
 * @returns A document.
 */
- (MSDocumentWrapper *)readWithPartition:(NSString *)partition documentId:(NSString *)documentId documentType:(Class)documentType readOptions:(MSReadOptions *)readOptions;

/**
 * Delete table.
 *
 * @param accountId The logged in user id.
 */
- (BOOL)deleteUserStorageWithAccountId:(NSString *)accountId;

/**
 * Create table.
 *
 * @param accountId The logged in user id..
 */
- (void)createUserStorageWithAccountId:(NSString *)accountId;

@end

NS_ASSUME_NONNULL_END
