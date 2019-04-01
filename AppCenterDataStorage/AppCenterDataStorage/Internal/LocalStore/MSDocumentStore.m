// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "AppCenter+Internal.h"
#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSDBStoragePrivate.h"
#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSDocumentWrapper.h"
#import "MSDocumentStorePrivate.h"
#import "MSUtility+StringFormatting.h"
#import "MSWriteOptions.h"

static const NSUInteger kMSSchemaVersion = 1;

@implementation MSDocumentStore

#pragma mark - Initialization

- (instancetype)init {

  /*
   * DO NOT modify schema without a migration plan and bumping database version.
   */
  MSDBSchema *schema = @{kMSAppDocumentTableName : [MSDocumentStore tableSchema]};
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
    _pendingOperationColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSPendingDownloadColumnName]).unsignedIntegerValue;
  }
  return self;
}

#pragma mark - Table Management


- (void)createTableWithTableName:(NSString *)tableName {
  [self.dbStorage executeQueryUsingBlock:^int(void *db) {
    MSDBSchema *schema = @{tableName : [MSDocumentStore tableSchema]};

    // Create table based on the schema.
    return (int)[MSDBStorage createTablesWithSchema:schema inOpenedDatabase:db];
  }];
}

- (BOOL)deleteTableWithPartition:(NSString *)partition {
  return [self.dbStorage executeQueryUsingBlock:^int(void *db) {
           NSString *tableName = [MSDocumentStore tableNameWithPartition:partition];
           if ([MSDBStorage tableExists:tableName inOpenedDatabase:db]) {
             NSString *deleteQuery = [NSString stringWithFormat:@"DROP TABLE \"%@\";", tableName];
             int result = [MSDBStorage executeNonSelectionQuery:deleteQuery inOpenedDatabase:db];
             if (result == SQLITE_OK) {
               MSLogVerbose([MSDataStore logTag], @"Document table %@ has been deleted", tableName);
             } else {
               MSLogError([MSDataStore logTag], @"Failed to delete the Document table %@", tableName);
             }
             return result;
           }
           return SQLITE_OK;
         }] == SQLITE_OK;
}

+ (NSString *)tableNameWithPartition:(NSString *)partition {
  if ([partition isEqualToString:MSDataStoreAppDocumentsPartition]) {
    return kMSAppDocumentTableName;
  } else {
    return kMSUserDocumentTableName;
  }
}

+ (NSArray<NSDictionary<NSString *, NSArray<NSString *> *> *> *)tableSchema {
  
  // TODO create composite key for partition and the document id
  return @[
    @{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
    @{kMSPartitionColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
    @{kMSDocumentIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}, @{kMSDocumentColumnName : @[ kMSSQLiteTypeText ]},
    @{kMSETagColumnName : @[ kMSSQLiteTypeText ]}, @{kMSExpirationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
    @{kMSDownloadTimeColumnName : @[ kMSSQLiteTypeInteger ]}, @{kMSOperationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
    @{kMSPendingDownloadColumnName : @[ kMSSQLiteTypeText ]}
  ];
}

@end
