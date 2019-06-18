// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "AppCenter+Internal.h"
#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSDBDocumentStorePrivate.h"
#import "MSDBStoragePrivate.h"
#import "MSData.h"
#import "MSDataConstants.h"
#import "MSDataErrorInternal.h"
#import "MSDataErrors.h"
#import "MSDataInternal.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapper.h"
#import "MSDocumentWrapperInternal.h"
#import "MSPageInternal.h"
#import "MSPaginatedDocumentsInternal.h"
#import "MSPendingOperation.h"
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
         expirationTime:(NSTimeInterval)expirationTime {

  // This is the same as [[NSDate date] timeIntervalSince1970] - but saves us from allocating an NSDate.
  NSTimeInterval now = NSDate.timeIntervalSinceReferenceDate + NSTimeIntervalSince1970;
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:token.partition];

  // If operation or etag is nil, pass NULL value, else use the actual value in this format '<ACTUAL_VALUE>' (note the single quotes).
  NSString *normalizedOperationString = operation != nil ? [NSString stringWithFormat:@"'%@'", operation] : @"NULL";
  NSString *normalizedEtagString = documentWrapper.eTag != nil ? [NSString stringWithFormat:@"'%@'", documentWrapper.eTag] : @"NULL";
  NSString *insertQuery = [NSString
      stringWithFormat:@"REPLACE INTO \"%@\" (\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\") "
                       @"VALUES ('%@', '%@', '%@', %@, %ld, '%ld', '%ld', %@)",
                       tableName, kMSPartitionColumnName, kMSDocumentIdColumnName, kMSDocumentColumnName, kMSETagColumnName,
                       kMSExpirationTimeColumnName, kMSDownloadTimeColumnName, kMSOperationTimeColumnName, kMSPendingOperationColumnName,
                       token.partition, documentWrapper.documentId, documentWrapper.jsonValue, normalizedEtagString, (long)expirationTime,
                       (long)now, (long)[documentWrapper.lastUpdatedDate timeIntervalSince1970], normalizedOperationString];
  int result = [self.dbStorage executeNonSelectionQuery:insertQuery];
  if (result != SQLITE_OK) {
    MSLogError([MSData logTag], @"Unable to update or replace local document, SQLite error code: %ld", (long)result);
  }
  return result == SQLITE_OK;
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
  NSTimeInterval expirationTime = (deviceTimeToLive == kMSDataTimeToLiveInfinite) ? kMSDataTimeToLiveInfinite : now + deviceTimeToLive;
  return [self upsertWithToken:token documentWrapper:documentWrapper operation:operation expirationTime:expirationTime];
}

- (BOOL)deleteWithToken:(MSTokenResult *)token documentId:(NSString *)documentId {
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:token.partition];
  NSString *deleteQuery = [NSString stringWithFormat:@"DELETE FROM \"%@\" WHERE \"%@\" = '%@' AND \"%@\" = '%@'", tableName,
                                                     kMSPartitionColumnName, token.partition, kMSDocumentIdColumnName, documentId];
  int result = [self.dbStorage executeNonSelectionQuery:deleteQuery];
  if (result != SQLITE_OK) {
    MSLogError([MSData logTag], @"Unable to delete local document, SQLite error code: %ld", (long)result);
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
    MSLogWarning([MSData logTag], @"%@", errorMessage);

    // Create error.
    MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorDocumentNotFound innerError:nil message:errorMessage];
    return [[MSDocumentWrapper alloc] initWithError:dataError partition:token.partition documentId:documentId];
  }

  // If the document is expired, return an error and delete it.
  long expirationTime = [(NSNumber *)(result[0][self.expirationTimeColumnIndex]) longValue];
  if (expirationTime != kMSDataTimeToLiveInfinite) {
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:expirationTime];
    NSDate *currentDate = [NSDate date];
    if (expirationDate && [expirationDate laterDate:currentDate] == currentDate) {
      NSString *errorMessage =
          [NSString stringWithFormat:@"Local document for partition '%@' and document ID '%@' expired at %@, discarding it",
                                     token.partition, documentId, expirationDate];
      MSLogWarning([MSData logTag], @"%@", errorMessage);
      [self deleteWithToken:token documentId:documentId];

      // Create error.
      MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorLocalDocumentExpired
                                                           innerError:nil
                                                              message:errorMessage];
      return [[MSDocumentWrapper alloc] initWithError:dataError partition:token.partition documentId:documentId];
    }
  }

  // Deserialize.
  NSString *jsonString = result[0][self.documentColumnIndex];
  NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  long lastUpdatedDateValue = [(NSNumber *)result[0][self.operationTimeColumnIndex] longValue];
  NSDate *lastUpdatedDate = lastUpdatedDateValue > 0 ? [NSDate dateWithTimeIntervalSince1970:lastUpdatedDateValue] : nil;

  // If operation is NSNull, change it to nil.
  NSString *pendingOperation = [self checkForNSNull:result[0][self.pendingOperationColumnIndex]];

  // If Etag is NSNull, change it to nil.
  NSString *etag = [self checkForNSNull:result[0][self.eTagColumnIndex]];
  return [MSDocumentUtils documentWrapperFromDocumentData:jsonData
                                             documentType:documentType
                                                     eTag:etag
                                          lastUpdatedDate:lastUpdatedDate
                                                partition:token.partition
                                               documentId:documentId
                                         pendingOperation:pendingOperation
                                          fromDeviceCache:YES];
}

- (MSPaginatedDocuments *)listWithToken:(MSTokenResult *)token
                              partition:(NSString *)partition
                           documentType:(Class)documentType
                            baseOptions:(MSBaseOptions *_Nullable)baseOptions {

  // Final list of documents.
  NSMutableArray<MSDocumentWrapper *> *localListItems = [NSMutableArray new];

  // Get effective device time to live.
  NSInteger deviceTimeToLive = baseOptions ? baseOptions.deviceTimeToLive : kMSDataTimeToLiveDefault;

  // Execute the query.
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:token.partition];
  NSString *selectionQuery =
      [NSString stringWithFormat:@"SELECT * FROM \"%@\" WHERE \"%@\" = \"%@\"", tableName, kMSPartitionColumnName, token.partition];
  NSArray *listResult = [self.dbStorage executeSelectionQuery:selectionQuery];
  NSDate *currentDate = [NSDate date];

  // Parse the documents.
  for (id documentRow in listResult) {

    // If an expired document is found exclude it from the list and delete it from the local store.
    long expirationTime = [(NSNumber *)(documentRow[self.expirationTimeColumnIndex]) longValue];
    NSString *documentId = documentRow[self.documentIdColumnIndex];
    if (expirationTime != kMSDataTimeToLiveInfinite) {
      NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:expirationTime];
      if (expirationDate && [expirationDate laterDate:currentDate] == currentDate) {
        NSString *warningMessage =
            [NSString stringWithFormat:@"Local document for partition '%@' and document ID '%@' expired at %@, discarding it",
                                       token.partition, documentId, expirationDate];
        MSLogWarning([MSData logTag], @"%@", warningMessage);

        // Delete the local document when found to be expired
        [self deleteWithToken:token documentId:documentId];
      } else if ([kMSPendingOperationDelete isEqualToString:documentRow[self.pendingOperationColumnIndex]]) {

        // Ignore document, if the pending operation is found to be Delete
        NSString *warningMessage = [NSString
            stringWithFormat:
                @"Local document pending deletion in local storage for partition '%@' and document ID '%@', excluding from the list",
                token.partition, documentId];
        MSLogError([MSData logTag], @"%@", warningMessage);
      } else {

        // Deserialize document.
        NSString *jsonString = documentRow[self.documentColumnIndex];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        long lastUpdatedDateValue = [(NSNumber *)documentRow[self.operationTimeColumnIndex] longValue];
        NSDate *lastUpdatedDate = lastUpdatedDateValue > 0 ? [NSDate dateWithTimeIntervalSince1970:lastUpdatedDateValue] : nil;

        // If operation is NSNull, change it to nil.
        NSString *pendingOperation = [self checkForNSNull:documentRow[self.pendingOperationColumnIndex]];

        // If Etag is NSNull, change it to nil.
        NSString *etag = [self checkForNSNull:documentRow[self.eTagColumnIndex]];
        MSDocumentWrapper *cachedDocument = [MSDocumentUtils documentWrapperFromDocumentData:jsonData
                                                                                documentType:documentType
                                                                                        eTag:etag
                                                                             lastUpdatedDate:lastUpdatedDate
                                                                                   partition:token.partition
                                                                                  documentId:documentId
                                                                            pendingOperation:pendingOperation
                                                                             fromDeviceCache:YES];
        [localListItems addObject:cachedDocument];

        // Push back cached document expiration time.
        [self updateDocumentWithToken:token
                currentCachedDocument:cachedDocument
                    newCachedDocument:cachedDocument
                     deviceTimeToLive:deviceTimeToLive
                            operation:cachedDocument.pendingOperation];
      }
    }
  }

  // Return an empty list if no documents were found.
  if (localListItems.count == 0) {
    NSString *warningMessage =
        [NSString stringWithFormat:@"Unable to find any document in local store for partition '%@'", token.partition];
    MSLogWarning([MSData logTag], @"%@", warningMessage);

    // return an empty list
    MSPaginatedDocuments *documents = [[MSPaginatedDocuments alloc] initWithPage:[[MSPage alloc] initWithItems:localListItems]
                                                                       partition:partition
                                                                    documentType:documentType
                                                                deviceTimeToLive:baseOptions.deviceTimeToLive
                                                               continuationToken:nil];
    return documents;
  }

  // Instantiate the paginated documents and return it.
  MSPage *page = [[MSPage alloc] initWithItems:localListItems];
  MSPaginatedDocuments *documents = [[MSPaginatedDocuments alloc] initWithPage:page
                                                                     partition:partition
                                                                  documentType:documentType
                                                              deviceTimeToLive:baseOptions.deviceTimeToLive
                                                             continuationToken:nil];
  return documents;
}

- (void)resetDatabase {
  [self.dbStorage dropDatabase];
  [self createTableWithTableName:kMSAppDocumentTableName];
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
  if ([partition isEqualToString:kMSDataAppDocumentsPartition]) {
    return kMSAppDocumentTableName;
  } else if ([partition rangeOfString:kMSDataAppDocumentsUserPartitionPrefix options:NSAnchoredSearch].location == 0) {
    return [NSString
        stringWithFormat:kMSUserDocumentTableNameFormat, [partition substringFromIndex:kMSDataAppDocumentsUserPartitionPrefix.length]];
  }
  return nil;
}

- (NSArray<MSPendingOperation *> *)pendingOperationsWithToken:(MSTokenResult *)token {
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:token.partition];
  NSString *selectionQuery =
      [NSString stringWithFormat:@"SELECT * FROM \"%@\" WHERE \"%@\" IS NOT NULL", tableName, kMSPendingOperationColumnName];
  NSArray *result = [self.dbStorage executeSelectionQuery:selectionQuery];
  NSMutableArray *pendingDocuments = [NSMutableArray new];

  // Return empty list if there are no pending documents.
  if (result.count == 0) {
    return pendingDocuments;
  }

  // Create object of MSPendingOperation for each row.
  for (id row in result) {
    NSString *documentId = row[self.documentIdColumnIndex];
    NSString *partition = row[self.partitionColumnIndex];

    // If the document is expired, log a message and delete it.
    NSNumber *ttlNumber = row[self.expirationTimeColumnIndex];
    long expirationTime = [ttlNumber longValue];
    if ([MSPendingOperation isExpiredWithExpirationTime:expirationTime]) {
      [self deleteWithToken:token documentId:documentId];
      MSLogInfo([MSData logTag], @"Document expired. Deleted from local cache: partition: %@, documentId: %@", partition, documentId);
      continue;
    }

    // Convert document json string to dictionary.
    NSString *documetnJsonString = row[self.documentColumnIndex];
    NSData *data = [documetnJsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *documentDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

    MSPendingOperation *pendingOperation = [[MSPendingOperation alloc] initWithOperation:row[self.pendingOperationColumnIndex]
                                                                               partition:partition
                                                                              documentId:documentId
                                                                                document:documentDictionary
                                                                                    etag:row[self.eTagColumnIndex]
                                                                          expirationTime:[ttlNumber doubleValue]];
    [pendingDocuments addObject:pendingOperation];
  }
  return pendingDocuments;
}

- (BOOL)hasPendingOperationsForPartition:(NSString *)partition {
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:partition];
  NSString *selectionQuery =
      [NSString stringWithFormat:@"SELECT count(*) FROM \"%@\" WHERE \"%@\" IS NOT NULL", tableName, kMSPendingOperationColumnName];

  NSArray<NSArray<NSNumber *> *> *result = [self.dbStorage executeSelectionQuery:selectionQuery];
  NSUInteger count = (result.count > 0) ? result[0][0].unsignedIntegerValue : 0;

  // If empty list
  return count != 0;
}

- (void)updateDocumentWithToken:(MSTokenResult *)token
          currentCachedDocument:(MSDocumentWrapper *)currentCachedDocument
              newCachedDocument:(MSDocumentWrapper *)newCachedDocument
               deviceTimeToLive:(NSInteger)deviceTimeToLive
                      operation:(NSString *_Nullable)operation {

  // If the device time to live does not allow it, remove document from local storage (whether it is here or not).
  if (deviceTimeToLive == kMSDataTimeToLiveNoCache) {
    MSLogInfo([MSData logTag], @"Removing document from local storage (partition: %@, id: %@)", token.partition,
              currentCachedDocument.documentId);
    [self deleteWithToken:token documentId:currentCachedDocument.documentId];
  }

  /*
   * If the cached document has a create or replace pending operation, and no eTags, and if the current operation is a
   * deletion, delete the document from the store.
   */
  else if (([kMSPendingOperationCreate isEqualToString:currentCachedDocument.pendingOperation] ||
            [kMSPendingOperationReplace isEqualToString:currentCachedDocument.pendingOperation]) &&
           !currentCachedDocument.eTag && operation && [kMSPendingOperationDelete isEqualToString:(NSString *)operation]) {
    MSLogInfo([MSData logTag], @"Removing never-synced document from local storage (partition: %@, id: %@)", token.partition,
              currentCachedDocument.documentId);
    [self deleteWithToken:token documentId:currentCachedDocument.documentId];
  }

  // Update document storage.
  else {
    MSLogInfo([MSData logTag], @"Updating/inserting document into local storage (partition: %@, id: %@, operation: %@)", token.partition,
              currentCachedDocument.documentId, operation);
    [self upsertWithToken:token documentWrapper:newCachedDocument operation:operation deviceTimeToLive:deviceTimeToLive];
  }
}

- (NSString *)checkForNSNull:(NSString *)column {

  // If column is NSNull, change it to nil.
  NSString *nullableColumn = column;
  NSString *fColumn = [nullableColumn isEqual:[NSNull null]] ? nil : nullableColumn;

  return fColumn;
}

@end
