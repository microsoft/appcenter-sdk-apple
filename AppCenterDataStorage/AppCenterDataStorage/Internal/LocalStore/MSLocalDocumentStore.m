// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSDBStoragePrivate.h"
#import "MSDocumentWrapper.h"
#import "MSUtility+StringFormatting.h"
#import "MSLocalDocumentStorePrivate.h"
#import "MSWriteOptions.h"
#import "MSDataStore.h"
#import "AppCenter+Internal.h"
#import "MSDataStoreInternal.h"

static const NSUInteger kMSSchemaVersion = 1;

@implementation MSLocalDocumentStore

#pragma mark - Initialization

- (instancetype)init {

    /*
    * DO NOT modify schema without a migration plan and bumping database version.
    */
    //TODO create composite key for partition and the document id
    MSDBSchema *schema = @{ kMSAppDocumentTableName : [MSLocalDocumentStore getTableSchema] };

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

-(void) createTableWithTableName:(NSString *)tableName
{
    [self executeQueryUsingBlock:^int(void *db) {
         MSDBSchema *schema = @{ tableName : [MSLocalDocumentStore getTableSchema] };
        
        // Create tables based on schema.
        return (int)[MSDBStorage createTablesWithSchema:schema inOpenedDatabase:db];
    }];
}

#pragma mark - Save Document

- (BOOL)saveDocument:(MSDocumentWrapper *) document partition:(NSString *)partitionType writeOptions:(MSWriteOptions *)options{
    if (!document) {
        return NO;
    }
    
    NSString *addDocumentQuery =
    [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\") VALUES ('%@', '%@', '%@','%@', '%lld', '%lld', '%lld', '%@')", [self getTableWithPartition:partitionType], kMSPartitionColumnName, kMSDocumentIdColumnName, kMSdocumentColumnName, kMSETagColumnName, kMSExpirationTimeColumnName, kMSDownloadTimeColumnName, kMSOperationTimeColumnName, kMSPendingDownloadColumnName, document.partition, document.documentId, document.jsonValue, document.eTag, (long long)options.deviceTimeToLive, (long long)[[NSDate date] timeIntervalSince1970], (long long)[[NSDate date] timeIntervalSince1970], (partitionType == Readonly ? nil : kMSPendingOperationCreate)];
    
    return [self executeQueryUsingBlock:^int(void *db) {
        
        // Try to insert.
        int result = [MSDBStorage executeNonSelectionQuery:addDocumentQuery inOpenedDatabase:db];
        if (result == SQLITE_OK) {
            MSLogVerbose([MSDataStore logTag], @"Document is stored with id: '%ld'", (long)sqlite3_last_insert_rowid(db));
        } else if (result == SQLITE_FULL) {
            MSLogError([MSDataStore logTag], @"Storage is full, discarding the document.");
        }
        return result;
        }] == SQLITE_OK;
    }

#pragma mark - DB deletion

-(bool) deleteTableWithPartition:(NSString*)partitionName
{
    return [self executeQueryUsingBlock:^int(void *db) {
        NSString *tableName = [self getTableWithPartition:partitionName];
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
    }] == SQLITE_OK;;
}

- (NSString *) getTableWithPartition:(NSString *)partitionName
{
    if ([partitionName isEqualToString:MSDataStoreAppDocumentsPartition]) {
        return kMSAppDocumentTableName;
    }else {
        return kMSUserDocumentTableName;
    }
}

+ (NSArray<NSDictionary<NSString *, NSArray<NSString *> *> *> *)getTableSchema {
    
    return @[
             @{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
             @{kMSPartitionColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
             @{kMSDocumentIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
             @{kMSdocumentColumnName : @[ kMSSQLiteTypeText ]},
             @{kMSETagColumnName : @[ kMSSQLiteTypeText ]},
             @{kMSExpirationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
             @{kMSDownloadTimeColumnName : @[ kMSSQLiteTypeInteger ]},
             @{kMSOperationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
             @{kMSPendingDownloadColumnName : @[ kMSSQLiteTypeText ]}
             ];
}
@end
