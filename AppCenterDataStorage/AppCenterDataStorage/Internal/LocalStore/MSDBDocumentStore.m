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
#import "MSDataStoreErrors.h"
#import "MSUtility+Date.h"

static const NSUInteger kMSSchemaVersion = 1;

@implementation MSDBDocumentStore

#pragma mark - Initialization

- (instancetype)init {

  /*
   * DO NOT modify schema without a migration plan and bumping database version.
   */
  MSDBSchema *schema = @{kMSAppDocumentTableName : [MSDBDocumentStore tableSchema]};
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

// TODO work item created to track this implementation
- (BOOL)createWithPartition:(NSString *)__unused partition
                   document:(MSDocumentWrapper *)__unused document
               writeOptions:(MSWriteOptions *)__unused writeOptions {
  return YES;
}

- (NSUInteger)createUserStorageWithAccountId:(NSString *)accountId {
  MSDBSchema *schema = @{[NSString stringWithFormat:kMSUserDocumentTableNameFormat, accountId] : [MSDBDocumentStore tableSchema]};

  // Create table based on the schema.
  return (int)[self.dbStorage createTablesWithSchema:schema];
}

- (BOOL)deleteUserStorageWithAccountId:(NSString *)accountId {
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, accountId];
  return [self.dbStorage dropTable:tableName];
}

- (MSDocumentWrapper *)readWithPartition:(NSString *)partition documentId:(NSString *)documentId documentType:(Class)documentType readOptions:(MSReadOptions *)readOptions {
  (void)readOptions;
  NSString *selectionQuery = [NSString stringWithFormat:@"SELECT * FROM \"%@\" WHERE \"%@\" = \"%@\" AND \"%@\" = \"%@\"", kMSAppDocumentTableName, kMSPartitionColumnName, partition, kMSDocumentIdColumnName, documentId];
  NSArray *result = [self.dbStorage executeSelectionQuery:selectionQuery];

  // Return an error if the entry could not be found in the database.
  if (result.count == 0) {
    NSString *errorMessage = [NSString stringWithFormat:@"Unable to find document in local database with partition key '%@' and document ID '%@'", partition, documentId];
    MSLogWarning([MSDataStore logTag], @"%@", errorMessage);
    NSError *error = [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                                  code:MSACDataStoreErrorLocalDocumentNotFound
                                              userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
    return [[MSDocumentWrapper alloc] initWithError:error documentId:documentId];
  }

  // If the document is expired, return an error and delete it.
  NSDate *expirationTime = [MSUtility dateFromISO8601:result[0][self.expirationTimeColumnIndex]];
  NSDate *currentDate = [NSDate date];
  if ([expirationTime laterDate:currentDate] == currentDate) {
    NSString *errorMessage = [NSString stringWithFormat:@"Local document with partition key '%@' and document ID '%@' expired at %@", partition, documentId, expirationTime];
    MSLogWarning([MSDataStore logTag], @"%@", errorMessage);
    NSError *error = [[NSError alloc] initWithDomain:kMSACDataStoreErrorDomain
                                                code:MSACDataStoreErrorLocalDocumentExpired
                                            userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
    [self deleteDocumentWithPartition:partition documentId:documentId];
    return [[MSDocumentWrapper alloc] initWithError:error documentId:documentId];
  }

  // Deserialize.
  NSString *jsonString = result[0][self.documentColumnIndex];
  NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  NSError *deserializeError;
  NSDictionary *documentDictionary = [NSJSONSerialization JSONObjectWithData:jsonData
                                                       options:0
                                                         error:&deserializeError];
  if (deserializeError) {
    MSLogWarning([MSDataStore logTag], @"Error deserializing data:%@", [deserializeError description]);
    return [[MSDocumentWrapper alloc] initWithError:deserializeError documentId:documentId];
  }
  id<MSSerializableDocument> document = [(id<MSSerializableDocument>)[documentType alloc] initFromDictionary:documentDictionary];
  return [[MSDocumentWrapper alloc] initWithDeserializedValue:document jsonValue:jsonString partition:partition documentId:documentId eTag:result[0][self.eTagColumnIndex] lastUpdatedDate:result[0][self.operationTimeColumnIndex]];
}

- (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId {
  (void)partition; (void)documentId;

  //TODO implement this.
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
