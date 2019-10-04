// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDBDocumentStore.h"
#import "MSDBStorage.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kMSDBDocumentFileName = @"Documents.sqlite";
static NSString *const kMSAppDocumentTableName = @"appDocuments";
static NSString *const kMSUserDocumentTableNameFormat = @"user_%@_documents";
static NSString *const kMSDataAppDocumentsUserPartitionPrefix = @"user-";
static NSString *const kMSIdColumnName = @"id";
static NSString *const kMSPartitionColumnName = @"partition";
static NSString *const kMSDocumentIdColumnName = @"document_id";
static NSString *const kMSDocumentColumnName = @"document";
static NSString *const kMSETagColumnName = @"etag";
static NSString *const kMSExpirationTimeColumnName = @"expiration_time";
static NSString *const kMSDownloadTimeColumnName = @"download_time";
static NSString *const kMSOperationTimeColumnName = @"operation_time";
static NSString *const kMSPendingOperationColumnName = @"pending_operation";

@protocol MSDatabaseConnection;

@interface MSDBDocumentStore ()

/**
 * "id" database column index.
 */
@property(nonatomic, readonly) NSUInteger idColumnIndex;

/**
 * "partition" database column index.
 */
@property(nonatomic, readonly) NSUInteger partitionColumnIndex;

/**
 * "documentId" database column index.
 */
@property(nonatomic, readonly) NSUInteger documentIdColumnIndex;

/**
 * "document" database column index.
 */
@property(nonatomic, readonly) NSUInteger documentColumnIndex;

/**
 * "eTag" database column index.
 */
@property(nonatomic, readonly) NSUInteger eTagColumnIndex;

/**
 * "expirationTime" database column index.
 */
@property(nonatomic, readonly) NSUInteger expirationTimeColumnIndex;

/**
 * "downloadTime" database column index.
 */
@property(nonatomic, readonly) NSUInteger downloadTimeColumnIndex;

/**
 * "operationTime" database column index.
 */
@property(nonatomic, readonly) NSUInteger operationTimeColumnIndex;

/**
 * "pendingOperation" database column index.
 */
@property(nonatomic, readonly) NSUInteger pendingOperationColumnIndex;

/**
 * A local store instance that is used to manage all operation on the sqLite instance.
 */
@property(nonatomic) MSDBStorage *dbStorage;

/**
 * The schema for the documents cache.
 */
+ (MSDBColumnsSchema *)columnsSchema;

/**
 * Return the table for a given token.
 *
 * @param token The token.
 *
 * @return The table name.
 */
+ (NSString *)tableNameForToken:(MSTokenResult *)token;

@end

NS_ASSUME_NONNULL_END
