// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "AppCenter+Internal.h"
#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSDBDocumentStorePrivate.h"
#import "MSDBStoragePrivate.h"
#import "MSDataStorageConstants.h"
#import "MSDataStore.h"
#import "MSDataStoreErrors.h"
#import "MSDataStoreInternal.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapperInternal.h"
#import "MSTokenResult.h"
#import "MSUtility+Date.h"
#import "MSUtility+StringFormatting.h"

static const NSUInteger kMSSchemaVersion = 1;

@implementation MSDBDocumentStore

#pragma mark - Initialization

- (instancetype)initWithDbStorage:(MSDBStorage *)dbStorage {
  if ((self = [super init])) {
    _dbStorage = dbStorage;
    MSDBSchema *schema = @{kMSAppDocumentTableName : MSDBDocumentStore.columnsSchema};
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
    [self createTableWithTableName:kMSAppDocumentTableName];
  }
  return self;
}

- (instancetype)init {

  /*
   * DO NOT modify schema without a migration plan and bumping database version.
   */
  MSDBStorage *dbStorage = [[MSDBStorage alloc] initWithVersion:kMSSchemaVersion filename:kMSDBDocumentFileName];
  return [self initWithDbStorage:dbStorage];
}

#pragma mark - Table Management

- (BOOL)createUserStorageWithAccountId:(NSString *)accountId {
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, accountId];
  return [self createTableWithTableName:tableName];
}

- (BOOL)createTableWithTableName:(NSString *)tableName {

  // Create table based on the schema.
  return [self.dbStorage createTable:tableName
                       columnsSchema:[MSDBDocumentStore columnsSchema]
             uniqueColumnsConstraint:@[ kMSPartitionColumnName, kMSDocumentIdColumnName ]];
}

- (BOOL)upsertWithToken:(MSTokenResult *)token
        documentWrapper:(MSDocumentWrapper *)documentWrapper
              operation:(NSString *_Nullable)operation
       deviceTimeToLive:(NSInteger)deviceTimeToLive {
  /*
   * Compute expiration time as now + device time to live (in seconds).
   * If device time to live is set to infinite, set expiration time as null in the database.
   * Note: If the cache/store is meant to be disabled, this method should not even be called.
   */

  // This is the same as [[NSDate date] timeIntervalSince1970] - but saves us from allocating an NSDate.
  NSTimeInterval now = NSDate.timeIntervalSinceReferenceDate + NSTimeIntervalSince1970;
  NSTimeInterval expirationTime = -1;
  if (deviceTimeToLive != kMSDataStoreTimeToLiveInfinite) {
    expirationTime = now + deviceTimeToLive;
  }
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:token.partition];
  NSString *insertQuery = [NSString
      stringWithFormat:@"REPLACE INTO \"%@\" (\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\") "
                       @"VALUES ('%@', '%@', '%@', '%@', %ld, '%ld', '%ld', '%@')",
                       tableName, kMSPartitionColumnName, kMSDocumentIdColumnName, kMSDocumentColumnName, kMSETagColumnName,
                       kMSExpirationTimeColumnName, kMSDownloadTimeColumnName, kMSOperationTimeColumnName, kMSPendingOperationColumnName,
                       token.partition, documentWrapper.documentId, documentWrapper.jsonValue, documentWrapper.eTag, (long)expirationTime,
                       (long)[documentWrapper.lastUpdatedDate timeIntervalSince1970], (long)now, operation];
  int result = [self.dbStorage executeNonSelectionQuery:insertQuery];
  if (result != SQLITE_OK) {
    MSLogError([MSDataStore logTag], @"Unable to update or replace local document, SQLite error code: %ld", (long)result);
  }
  return result == SQLITE_OK;
}

- (BOOL)deleteWithToken:(MSTokenResult *)token documentId:(NSString *)documentId {
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:token.partition];
  NSString *deleteQuery = [NSString stringWithFormat:@"DELETE FROM \"%@\" WHERE \"%@\" = '%@' AND \"%@\" = '%@'", tableName,
                                                     kMSPartitionColumnName, token.partition, kMSDocumentIdColumnName, documentId];
  int result = [self.dbStorage executeNonSelectionQuery:deleteQuery];
  if (result != SQLITE_OK) {
    MSLogError([MSDataStore logTag], @"Unable to delete local document, SQLite error code: %ld", (long)result);
  }
  return result == SQLITE_OK;
}

- (BOOL)deleteUserStorageWithAccountId:(NSString *)accountId {
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, accountId];
  return [self.dbStorage dropTable:tableName];
}

- (MSDocumentWrapper *)readWithToken:(MSTokenResult *)token documentId:(NSString *)documentId documentType:(Class)documentType {
  // Execute the query.
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:token.partition];
  NSString *selectionQuery = [NSString stringWithFormat:@"SELECT * FROM \"%@\" WHERE \"%@\" = \"%@\" AND \"%@\" = \"%@\"", tableName,
                                                        kMSPartitionColumnName, token.partition, kMSDocumentIdColumnName, documentId];
  NSArray *result = [self.dbStorage executeSelectionQuery:selectionQuery];

  // Return an error if the document could not be found.
  if (result.count == 0) {
    NSString *errorMessage = [NSString
        stringWithFormat:@"Unable to find document in local store for partition '%@' and document ID '%@'", token.partition, documentId];
    MSLogWarning([MSDataStore logTag], @"%@", errorMessage);
    NSError *error = [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                                code:MSACDataStoreErrorDocumentNotFound
                                            userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
    return [[MSDocumentWrapper alloc] initWithError:error documentId:documentId];
  }

  // If the document is expired, return an error and delete it.
  long expirationTime = [(NSNumber *)(result[0][self.expirationTimeColumnIndex]) longValue];
  if (expirationTime != kMSDataStoreTimeToLiveInfinite) {
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:expirationTime];
    NSDate *currentDate = [NSDate date];
    if (expirationDate && [expirationDate laterDate:currentDate] == currentDate) {
      NSString *errorMessage =
          [NSString stringWithFormat:@"Local document for partition '%@' and document ID '%@' expired at %@, discarding it",
                                     token.partition, documentId, expirationDate];
      MSLogWarning([MSDataStore logTag], @"%@", errorMessage);
      NSError *error = [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                                  code:MSACDataStoreErrorLocalDocumentExpired
                                              userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
      [self deleteWithToken:token documentId:documentId];
      return [[MSDocumentWrapper alloc] initWithError:error documentId:documentId];
    }
  }

  // Deserialize.
  NSString *jsonString = result[0][self.documentColumnIndex];
  NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  long lastUpdatedDate = [(NSNumber *)result[0][self.operationTimeColumnIndex] longValue];
  NSString *pendingOperation = result[0][self.pendingOperationColumnIndex];
  return [MSDocumentUtils documentWrapperFromDocumentData:jsonData
                                             documentType:documentType
                                                     eTag:result[0][self.eTagColumnIndex]
                                          lastUpdatedDate:[NSDate dateWithTimeIntervalSince1970:lastUpdatedDate]
                                                partition:token.partition
                                               documentId:documentId
                                         pendingOperation:pendingOperation
                                          fromDeviceCache:YES];
}

- (void)deleteAllTables {
  // Delete all the tables.
  [self.dbStorage dropAllTables];
}

+ (MSDBColumnsSchema *)columnsSchema {
  // clang-format off
  return @[
           @{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
           @{kMSPartitionColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
           @{kMSDocumentIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
           @{kMSDocumentColumnName : @[ kMSSQLiteTypeText ]},
           @{kMSETagColumnName : @[ kMSSQLiteTypeText ]},
           @{kMSExpirationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
           @{kMSDownloadTimeColumnName : @[ kMSSQLiteTypeInteger ]},
           @{kMSOperationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
           @{kMSPendingOperationColumnName : @[ kMSSQLiteTypeText ]}
           ];
  // clang-format on
}

+ (NSString *)tableNameForPartition:(NSString *)partition {
  if ([partition isEqualToString:kMSDataStoreAppDocumentsPartition]) {
    return kMSAppDocumentTableName;
  } else if ([partition rangeOfString:kMSDataStoreAppDocumentsUserPartitionPrefix options:NSAnchoredSearch].location == 0) {
    return [NSString
        stringWithFormat:kMSUserDocumentTableNameFormat, [partition substringFromIndex:kMSDataStoreAppDocumentsUserPartitionPrefix.length]];
  }
  return nil;
}

@end
