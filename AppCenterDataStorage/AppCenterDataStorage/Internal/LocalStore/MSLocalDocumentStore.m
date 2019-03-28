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
#import "MSLocalDocumentStorePrivate.h"
#import "MSUtility+StringFormatting.h"
#import "MSWriteOptions.h"

static const NSUInteger kMSSchemaVersion = 1;

@implementation MSLocalDocumentStore

#pragma mark - Initialization

- (instancetype)init {

  /*
   * DO NOT modify schema without a migration plan and bumping database version.
   */

  // TODO create composite key for partition and the document id
  MSDBSchema *schema = @{kMSAppDocumentTableName : [MSLocalDocumentStore tableSchema]};
  if ((self = [super initWithSchema:schema version:kMSSchemaVersion filename:kMSDBDocumentFileName])) {
    NSDictionary *columnIndexes = [MSDBStorage columnsIndexes:schema];
    _idColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSIdColumnName]).unsignedIntegerValue;
    _partitionColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSPartitionColumnName]).unsignedIntegerValue;
    _documentIdColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSDocumentIdColumnName]).unsignedIntegerValue;
    _documentColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSdocumentColumnName]).unsignedIntegerValue;
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
  [self executeQueryUsingBlock:^int(void *db) {
    MSDBSchema *schema = @{tableName : [MSLocalDocumentStore tableSchema]};

    // Create tables based on the schema.
    return (int)[MSDBStorage createTablesWithSchema:schema inOpenedDatabase:db];
  }];
}

- (BOOL)deleteTableWithPartition:(NSString *)partition {
  return [self executeQueryUsingBlock:^int(void *db) {
           NSString *tableName = [MSLocalDocumentStore tableNameWithPartition:partition];
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
  return @[
    @{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
    @{kMSPartitionColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
    @{kMSDocumentIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}, @{kMSdocumentColumnName : @[ kMSSQLiteTypeText ]},
    @{kMSETagColumnName : @[ kMSSQLiteTypeText ]}, @{kMSExpirationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
    @{kMSDownloadTimeColumnName : @[ kMSSQLiteTypeInteger ]}, @{kMSOperationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
    @{kMSPendingDownloadColumnName : @[ kMSSQLiteTypeText ]}
  ];
}

@end
