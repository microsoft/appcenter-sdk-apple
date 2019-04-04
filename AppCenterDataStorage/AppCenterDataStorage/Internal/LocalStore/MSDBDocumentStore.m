// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "AppCenter+Internal.h"
#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSDBDocumentStorePrivate.h"
#import "MSDBStoragePrivate.h"
#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSDocumentWrapper.h"
#import "MSUtility+StringFormatting.h"
#import "MSWriteOptions.h"

static const NSUInteger kMSSchemaVersion = 1;

@implementation MSDBDocumentStore

#pragma mark - Initialization

- (instancetype)init {

  /*
   * DO NOT modify schema without a migration plan and bumping database version.
   */
  MSDBSchema *schema = @{kMSAppDocumentTableName : [MSDBDocumentStore columnsSchema]};
  if ((self = [super init])) {
    self.dbStorage = [[MSDBStorage alloc] initWithSchema:schema version:kMSSchemaVersion filename:kMSDBDocumentFileName];
    NSDictionary *columnIndexes = [MSDBStorage columnsIndexes:schema];
    _idColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSIdColumnName]).unsignedIntegerValue;
    _partitionColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSPartitionColumnName]).unsignedIntegerValue;
    _documentIdColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSDocumentIdColumnName]).unsignedIntegerValue;
    _documentColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSDocumentColumnName]).unsignedIntegerValue;
    _eTagColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSETagColumnName]).unsignedIntegerValue;
    _expirationTimeColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSExpirationTimeColumnName]).unsignedIntegerValue;
    _downloadTimeColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSDownloadTimeColumnName]).unsignedIntegerValue;
    _operationTimeColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSOperationTimeColumnName]).unsignedIntegerValue;
    _pendingOperationColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSPendingOperationColumnName]).unsignedIntegerValue;
  }
  return self;
}

#pragma mark - Table Management

- (BOOL)upsertWithPartition:(NSString *)partition
                   document:(id<MSSerializableDocument>)document
                 documentId:(NSString *)documentId
            lastUpdatedDate:(NSDate *)lastUpdatedDate
                       eTag:(NSString *)eTag
                  operation:(NSString *_Nullable)operation
                    options:(MSBaseOptions *)options {
  NSString *base64Data;
  if (document) {
    NSDictionary *documentDict = [document serializeToDictionary];
    NSData *documentData = [NSKeyedArchiver archivedDataWithRootObject:documentDict];
    base64Data = [documentData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
  }
  NSDate *now = [NSDate date];
  NSDate *expirationTime = [now dateByAddingTimeInterval:options.deviceTimeToLive];
  NSString *insertQuery =
      [NSString stringWithFormat:@"REPLACE INTO '%@' ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@') "
                                 @"VALUES ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@')",
                                 kMSAppDocumentTableName, kMSIdColumnName, kMSPartitionColumnName, kMSDocumentIdColumnName,
                                 kMSDocumentColumnName, kMSETagColumnName, kMSExpirationTimeColumnName, kMSDownloadTimeColumnName,
                                 kMSOperationTimeColumnName, kMSPendingOperationColumnName, @0, partition, documentId, base64Data, eTag,
                                 expirationTime, lastUpdatedDate, now, operation];
  NSInteger result = [self.dbStorage executeNonSelectionQuery:insertQuery];
  if (result != SQLITE_OK) {
    MSLogError([MSDataStore logTag], @"Unable to update or replace cached document, SQLite error code: %ld", (long)result);
  }
  return result == SQLITE_OK;
}

- (BOOL)deleteWithPartition:(NSString *)partition documentId:(NSString *)documentId {
  NSString *deleteQuery = [NSString stringWithFormat:@"DELETE FROM '%@' WHERE '%@' = '%@' AND '%@' = '%@'", kMSAppDocumentTableName,
                                                     kMSPartitionColumnName, partition, kMSDocumentIdColumnName, documentId];
  NSInteger result = [self.dbStorage executeNonSelectionQuery:deleteQuery];
  if (result != SQLITE_OK) {
    MSLogError([MSDataStore logTag], @"Unable to delete cached document, SQLite error code: %ld", (long)result);
  }
  return result == SQLITE_OK;
}

- (BOOL)createUserStorageWithAccountId:(NSString *)accountId {

  // Create table based on the schema.
  return [self.dbStorage createTable:[NSString stringWithFormat:kMSUserDocumentTableNameFormat, accountId]
                       columnsSchema:[MSDBDocumentStore columnsSchema]];
}

- (BOOL)deleteUserStorageWithAccountId:(NSString *)accountId {
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, accountId];
  return [self.dbStorage dropTable:tableName];
}

+ (MSDBColumnsSchema *)columnsSchema {

  // TODO create composite key for partition and the document id
  NSMutableArray *schema = [NSMutableArray new];
  [schema addObject:@{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]}];
  [schema addObject:@{kMSPartitionColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}];
  [schema addObject:@{kMSDocumentIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}];
  [schema addObject:@{kMSDocumentColumnName : @[ kMSSQLiteTypeText ]}];
  [schema addObject:@{kMSETagColumnName : @[ kMSSQLiteTypeText ]}];
  [schema addObject:@{kMSExpirationTimeColumnName : @[ kMSSQLiteTypeInteger ]}];
  [schema addObject:@{kMSDownloadTimeColumnName : @[ kMSSQLiteTypeInteger ]}];
  [schema addObject:@{kMSOperationTimeColumnName : @[ kMSSQLiteTypeInteger ]}];
  [schema addObject:@{kMSPendingOperationColumnName : @[ kMSSQLiteTypeText ]}];
  return schema;
}

@end
