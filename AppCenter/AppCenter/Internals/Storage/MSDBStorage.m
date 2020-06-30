// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "MSAppCenterInternal.h"
#import "MSDBStoragePrivate.h"
#import "MSStorageBindableArray.h"
#import "MSUtility+File.h"

static dispatch_once_t sqliteConfigurationResultOnceToken;
static int sqliteConfigurationResult = SQLITE_ERROR;

@implementation MSDBStorage

+ (void)load {

  /*
   * Configure SQLite at load time to invoke configuration only once and before opening a DB.
   * If it is custom SQLite library we need to turn on URI filename capability.
   */
  sqliteConfigurationResult = [self configureSQLite];
}

- (instancetype)initWithSchema:(MSDBSchema *)schema version:(NSUInteger)version filename:(NSString *)filename {
  _schema = schema;
  
  // Log SQLite configuration result only once at init time because log level won't be set at load time.
  dispatch_once(&sqliteConfigurationResultOnceToken, ^{
    if (sqliteConfigurationResult == SQLITE_OK) {
      MSLogDebug([MSAppCenter logTag], @"SQLite global configuration successfully updated.");
    } else {
      NSString *errorString;
      if (@available(macOS 10.10, *)) {
        errorString = [NSString stringWithUTF8String:sqlite3_errstr(sqliteConfigurationResult)];
      } else {
        errorString = @(sqliteConfigurationResult).stringValue;
      }
      MSLogError([MSAppCenter logTag], @"Failed to update SQLite global configuration. Error: %@.", errorString);
    } 
  });
  if ((self = [super init])) {
    int result = [self configureDatabaseWithSchema:schema version:version filename:filename];
    if (result == SQLITE_CORRUPT || result == SQLITE_NOTADB) {
      [self dropDatabase];
      result = [self configureDatabaseWithSchema:schema version:version filename:filename];
    }
    if (result != SQLITE_OK) {
      MSLogError([MSAppCenter logTag], @"Failed to initialize database.");
    }
  }
  return self;
}

- (instancetype)initWithVersion:(NSUInteger)version filename:(NSString *)filename {
  return [self initWithSchema:nil version:version filename:filename];
}

- (int)configureDatabaseWithSchema:(MSDBSchema *)schema version:(NSUInteger)version filename:(NSString *)filename {
  BOOL newDatabase = ![MSUtility fileExistsForPathComponent:filename];
  self.dbFileURL = [MSUtility createFileAtPathComponent:filename withData:nil atomically:NO forceOverwrite:NO];
  self.maxSizeInBytes = kMSDefaultDatabaseSizeInBytes;
  int result;
  sqlite3 *db = [MSDBStorage openDatabaseAtFileURL:self.dbFileURL withResult:&result];
  if (result != SQLITE_OK) {
    return result;
  }
  self.pageSize = [MSDBStorage getPageSizeInOpenedDatabase:db];
  NSUInteger databaseVersion = [MSDBStorage versionInOpenedDatabase:db result:&result];
  if (result != SQLITE_OK) {
    sqlite3_close(db);
    return result;
  }

  // Create table.
  if (schema) {
    result = [MSDBStorage createTablesWithSchema:schema inOpenedDatabase:db];
    if (result != SQLITE_OK) {
      MSLogError([MSAppCenter logTag], @"Failed to create tables with schema with error \"%d\".", result);
      sqlite3_close(db);
      return result;
    }
  }
  if (newDatabase) {
    MSLogInfo([MSAppCenter logTag], @"Created \"%@\" database with %lu version.", filename, (unsigned long)version);
    [self customizeDatabase:db];
  } else if (databaseVersion < version) {
    MSLogInfo([MSAppCenter logTag], @"Migrating \"%@\" database from version %lu to %lu.", filename, (unsigned long)databaseVersion,
              (unsigned long)version);
    [self migrateDatabase:db fromVersion:databaseVersion];
  }
  [MSDBStorage enableAutoVacuumInOpenedDatabase:db];
  [MSDBStorage setVersion:version inOpenedDatabase:db];
  sqlite3_close(db);
  return result;
}

- (int)executeQueryUsingBlock:(MSDBStorageQueryBlock)callback {
  int result;
  sqlite3 *db = [MSDBStorage openDatabaseAtFileURL:self.dbFileURL withResult:&result];
  if (!db) {
    return result;
  }

  // The value is stored as part of the database connection and must be reset every time the database is opened.
  long maxPageCount = self.maxSizeInBytes / self.pageSize;
  result = [MSDBStorage setMaxPageCount:maxPageCount inOpenedDatabase:db];

  // Do not proceed with the query if the database is corrupted.
  if (result == SQLITE_CORRUPT || result == SQLITE_NOTADB) {
    sqlite3_close(db);
    return result;
  }

  // Log a warning if max page count can't be set.
  if (result != SQLITE_OK) {
    MSLogError([MSAppCenter logTag], @"Failed to open database with specified maximum size constraint.");
  }
  result = callback(db);
  sqlite3_close(db);
  return result;
}

- (void)dropDatabase {
  BOOL result = [MSUtility deleteFileAtURL:self.dbFileURL];
  if (result) {
    MSLogVerbose([MSAppCenter logTag], @"Database %@ has been deleted.", (NSString * _Nonnull) self.dbFileURL.absoluteString);
  } else {
    MSLogError([MSAppCenter logTag], @"Failed to delete database.");
  }
}

- (BOOL)dropTable:(NSString *)tableName {
  return [self executeQueryUsingBlock:^int(void *db) {
    if ([MSDBStorage tableExists:tableName inOpenedDatabase:db]) {
      NSString *deleteQuery = [NSString stringWithFormat:@"DROP TABLE \"%@\";", tableName];
      int result = [MSDBStorage executeNonSelectionQuery:deleteQuery inOpenedDatabase:db];
      if (result == SQLITE_OK) {
        MSLogVerbose([MSAppCenter logTag], @"Table %@ has been deleted", tableName);
      } else {
        MSLogError([MSAppCenter logTag], @"Failed to delete table %@", tableName);
      }
      return result;
    }
    return SQLITE_OK;
  }] == SQLITE_OK;
}

- (BOOL)createTable:(NSString *)tableName
              columnsSchema:(MSDBColumnsSchema *)columnsSchema {
  return [self executeQueryUsingBlock:^int(void *db) {
           if (![MSDBStorage tableExists:tableName inOpenedDatabase:db]) {
             NSString *createQuery =
                 [NSString stringWithFormat:@"CREATE TABLE \"%@\" (%@);", tableName,
                                            [MSDBStorage columnsQueryFromColumnsSchema:columnsSchema]];
             int result = [MSDBStorage executeNonSelectionQuery:createQuery inOpenedDatabase:db];
             if (result == SQLITE_OK) {
               MSLogVerbose([MSAppCenter logTag], @"Table %@ has been created", tableName);
             } else {
               MSLogError([MSAppCenter logTag], @"Failed to create table %@", tableName);
             }
             return result;
           }
           return SQLITE_OK;
         }] == SQLITE_OK;
}

+ (NSString *)columnsQueryFromColumnsSchema:(MSDBColumnsSchema *)columnsSchema {
  NSMutableArray *columnQueries = [NSMutableArray new];

  // Browse columns.
  for (NSUInteger i = 0; i < columnsSchema.count; i++) {
    NSString *columnName = columnsSchema[i].allKeys[0];

    // Compute column query.
    [columnQueries
        addObject:[NSString stringWithFormat:@"\"%@\" %@", columnName, [columnsSchema[i][columnName] componentsJoinedByString:@" "]]];
  }
  return [columnQueries componentsJoinedByString:@", "];
}

+ (int)createTablesWithSchema:(MSDBSchema *)schema inOpenedDatabase:(void *)db {
  int result = SQLITE_OK;
  NSMutableArray *tableQueries = [NSMutableArray new];

  // Browse tables.
  for (NSString *tableName in schema) {

    // Optimization, don't even compute the query if the table already exists.
    if ([self tableExists:tableName inOpenedDatabase:db result:&result]) {
      if (result != SQLITE_OK) {
        return result;
      }
      continue;
    }

    // Compute table query.
    [tableQueries addObject:[NSString stringWithFormat:@"CREATE TABLE \"%@\" (%@);", tableName,
                                                       [MSDBStorage columnsQueryFromColumnsSchema:schema[tableName]]]];
  }

  // Create the tables.
  if (tableQueries.count > 0) {

    /*
     * We do not join queries with ';' because we do not execute a non-selection query using `exec`.
     * We are using `step`, and `step` can only handle one-line statements.
     */
    for (NSString *tableQuery in tableQueries) {
      result = [self executeNonSelectionQuery:tableQuery inOpenedDatabase:db];
      if (result != SQLITE_OK) {
        return result;
      }
    }
  }
  return result;
}

+ (NSDictionary *)columnsIndexes:(MSDBSchema *)schema {
  NSMutableDictionary *dbColumnsIndexes = [NSMutableDictionary new];
  for (NSString *tableName in schema) {
    NSMutableDictionary *tableColumnsIndexes = [NSMutableDictionary new];
    NSArray<NSDictionary *> *columns = schema[tableName];
    for (NSUInteger i = 0; i < columns.count; i++) {
      NSString *columnName = columns[i].allKeys[0];
      tableColumnsIndexes[columnName] = @(i);
    }
    dbColumnsIndexes[tableName] = tableColumnsIndexes;
  }
  return dbColumnsIndexes;
}

+ (BOOL)tableExists:(NSString *)tableName inOpenedDatabase:(void *)db {
  return [MSDBStorage tableExists:tableName inOpenedDatabase:db result:nil];
}

+ (BOOL)tableExists:(NSString *)tableName inOpenedDatabase:(void *)db result:(int *)result {
  MSStorageBindableArray *values = [MSStorageBindableArray new];
  [values addString:tableName];
  NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM \"sqlite_master\" WHERE \"type\"='table' AND \"name\"=?;"];
  NSArray<NSArray *> *entries = [MSDBStorage executeSelectionQuery:query inOpenedDatabase:db result:result withValues:values];
  return entries.count > 0 && entries[0].count > 0 ? [(NSNumber *)entries[0][0] boolValue] : NO;
}

+ (NSUInteger)versionInOpenedDatabase:(void *)db result:(int *)result {
  NSArray<NSArray *> *entries = [MSDBStorage executeSelectionQuery:@"PRAGMA user_version" inOpenedDatabase:db result:result withValues:nil];
  return entries.count > 0 && entries[0].count > 0 ? [(NSNumber *)entries[0][0] unsignedIntegerValue] : 0;
}

+ (void)setVersion:(NSUInteger)version inOpenedDatabase:(void *)db {
  NSString *query = [NSString stringWithFormat:@"PRAGMA user_version = %lu", (unsigned long)version];

  // We use a selection query here because pragma set returns a value.
  [MSDBStorage executeSelectionQuery:query inOpenedDatabase:db withValues:nil];
}

+ (void)enableAutoVacuumInOpenedDatabase:(void *)db {
  NSArray<NSArray *> *result = [MSDBStorage executeSelectionQuery:@"PRAGMA auto_vacuum" inOpenedDatabase:db withValues:nil];
  int vacuumMode = 0;
  if (result.count > 0 && result[0].count > 0) {
    vacuumMode = [(NSNumber *)result[0][0] intValue];
  }
  BOOL autoVacuumDisabled = vacuumMode != 1;

  /*
   * If `auto_vacuum` is disabled, change it to `FULL` and then manually `VACUUM` the database. Per the SQLite docs, changing the state of
   * `auto_vacuum` must be followed by a manual `VACUUM` before the change can take effect (for more information,
   * see https://www.sqlite.org/pragma.html#pragma_auto_vacuum).
   */
  if (autoVacuumDisabled) {
    MSLogDebug([MSAppCenter logTag], @"Vacuuming database and enabling auto_vacuum");

    // We use a selection query here because pragma set returns a value.
    [MSDBStorage executeSelectionQuery:@"PRAGMA auto_vacuum = FULL;" inOpenedDatabase:db withValues:nil];
    [MSDBStorage executeSelectionQuery:@"VACUUM;" inOpenedDatabase:db withValues:nil];
  }
}

- (NSUInteger)countEntriesForTable:(NSString *)tableName
                         condition:(nullable NSString *)condition
                        withValues:(nullable MSStorageBindableArray *)values {
  NSMutableString *countLogQuery = [NSMutableString stringWithFormat:@"SELECT COUNT(*) FROM \"%@\" ", tableName];
  if (condition.length > 0) {
    [countLogQuery appendFormat:@"WHERE %@", condition];
  }
  NSArray<NSArray<NSNumber *> *> *result = [self executeSelectionQuery:countLogQuery withValues:values];
  return (result.count > 0) ? result[0][0].unsignedIntegerValue : 0;
}

+ (int)executeNonSelectionQuery:(NSString *)query inOpenedDatabase:(void *)db {
  return [self executeNonSelectionQuery:query inOpenedDatabase:db withValues:nil];
}

- (int)executeNonSelectionQuery:(NSString *)query {
  return [self executeNonSelectionQuery:query withValues:nil];
}

- (int)executeNonSelectionQuery:(NSString *)query withValues:(nullable MSStorageBindableArray *)values {
  return [self executeQueryUsingBlock:^int(void *db) {
    return [MSDBStorage executeNonSelectionQuery:query inOpenedDatabase:db withValues:values];
  }];
}

+ (int)executeNonSelectionQuery:(NSString *)query inOpenedDatabase:(void *)db withValues:(nullable MSStorageBindableArray *)values {
  return [MSDBStorage executeQuery:query
                  inOpenedDatabase:db
                        withValues:values
                        usingBlock:^(void *statement) {
                          int stepResult = sqlite3_step(statement);
                          if (stepResult == SQLITE_DONE) {
                            return SQLITE_OK;
                          }
                          NSString *errorMessage = [NSString stringWithUTF8String:sqlite3_errmsg(db)];
                          if (stepResult == SQLITE_CORRUPT || stepResult == SQLITE_NOTADB) {
                            MSLogError([MSAppCenter logTag], @"A database file is corrupted, result=%d\n\t%@", stepResult, errorMessage);
                          } else if (stepResult == SQLITE_FULL) {
                            MSLogDebug([MSAppCenter logTag], @"Query failed with error: %d\n\t%@", stepResult, errorMessage);
                          } else {
                            MSLogError([MSAppCenter logTag], @"Could not execute the statement, result=%d\n\t%@", stepResult, errorMessage);
                          }
                          return stepResult;
                        }];
}

+ (int)executeQuery:(NSString *)query
    inOpenedDatabase:(void *)db
          withValues:(nullable MSStorageBindableArray *)values
          usingBlock:(MSDBStorageQueryBlock)block {
  sqlite3_stmt *statement = NULL;
  int result = sqlite3_prepare_v2(db, [query UTF8String], -1, &statement, NULL);
  if (result != SQLITE_OK) {
    NSString *errorMessage = [NSString stringWithUTF8String:sqlite3_errmsg(db)];
    MSLogError([MSAppCenter logTag], @"Failed to prepare SQLite statement, result=%d\n\t%@", result, errorMessage);
    return result;
  }
  result = [values bindAllValuesWithStatement:statement inOpenedDatabase:db];
  if (result == SQLITE_OK) {
    result = block(statement);
  }
  int finalizeResult = sqlite3_finalize(statement);
  if (finalizeResult != SQLITE_OK) {
    NSString *errorMessage = [NSString stringWithUTF8String:sqlite3_errmsg(db)];
    MSLogError([MSAppCenter logTag], @"Failed to finalize SQLite statement, result=%d\n\t%@", finalizeResult, errorMessage);
  }
  return result;
}

- (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query withValues:(nullable MSStorageBindableArray *)values {
  __block NSArray<NSArray *> *entries = nil;
  [self executeQueryUsingBlock:^int(void *db) {
    entries = [MSDBStorage executeSelectionQuery:query inOpenedDatabase:db withValues:values];
    return SQLITE_OK;
  }];
  return entries ?: [NSArray<NSArray *> new];
}

+ (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query
                             inOpenedDatabase:(void *)db
                                   withValues:(nullable MSStorageBindableArray *)values {
  return [self executeSelectionQuery:query inOpenedDatabase:db result:nil withValues:values];
}

+ (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query
                             inOpenedDatabase:(void *)db
                                       result:(int *)result
                                   withValues:(nullable MSStorageBindableArray *)values {
  NSMutableArray<NSMutableArray *> *entries = [NSMutableArray<NSMutableArray *> new];
  int queryResult = [MSDBStorage executeQuery:query
                             inOpenedDatabase:db
                                   withValues:values
                                   usingBlock:^(void *statement) {
                                     int stepResult;

                                     // Loop on rows.
                                     while ((stepResult = sqlite3_step(statement)) == SQLITE_ROW) {
                                       NSMutableArray *entry = [NSMutableArray new];

                                       // Loop on columns.
                                       for (int i = 0; i < sqlite3_column_count(statement); i++) {
                                         NSObject *value = [MSDBStorage columnValueFromStatement:statement atIndex:i];
                                         [entry addObject:value];
                                       }
                                       if (entry.count > 0) {
                                         [entries addObject:entry];
                                       }
                                     }
                                     if (stepResult != SQLITE_DONE) {
                                       NSString *errorMessage = [NSString stringWithUTF8String:sqlite3_errmsg(db)];
                                       MSLogError([MSAppCenter logTag], @"Query failed with error: %d\n\t%@", stepResult, errorMessage);
                                       return stepResult;
                                     }
                                     return SQLITE_OK;
                                   }];
  if (result) {
    *result = queryResult;
  }
  return entries;
}

+ (NSObject *)columnValueFromStatement:(sqlite3_stmt *)statement atIndex:(int)index {

  /*
   * Convert values.
   */
  int columnType = sqlite3_column_type(statement, index);
  switch (columnType) {
  case SQLITE_INTEGER:
    return @(sqlite3_column_int(statement, index));
  case SQLITE_TEXT:
    return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, index)];
  case SQLITE_NULL:
    return [NSNull null];
  default:
    MSLogError([MSAppCenter logTag], @"Could not retrieve column value at index %d from statement: unknown type %d.", index, columnType);
    return [NSNull null];
  }
}

- (void)customizeDatabase:(void *)__unused db {
}

- (void)migrateDatabase:(void *)__unused db fromVersion:(NSUInteger)__unused version {
}

- (void)setMaxStorageSize:(long)sizeInBytes completionHandler:(nullable void (^)(BOOL))completionHandler {
  int result;
  BOOL success;
  sqlite3 *db = [MSDBStorage openDatabaseAtFileURL:self.dbFileURL withResult:&result];
  if (!db) {
    return;
  }

  // Check the current number of pages in the database to determine whether the requested size will shrink the database.
  long currentPageCount = [MSDBStorage getPageCountInOpenedDatabase:db];
  MSLogDebug([MSAppCenter logTag], @"Found %ld pages in the database.", currentPageCount);
  long requestedMaxPageCount = sizeInBytes % self.pageSize ? sizeInBytes / self.pageSize + 1 : sizeInBytes / self.pageSize;
  if (currentPageCount > requestedMaxPageCount) {
    MSLogWarning([MSAppCenter logTag],
                 @"Cannot change database size to %ld bytes as it would cause a loss of data. "
                  "Maximum database size will not be changed.",
                 sizeInBytes);
    success = NO;
  } else {

    // Attempt to set the limit and check the page count to make sure the given limit works.
    result = [MSDBStorage setMaxPageCount:requestedMaxPageCount inOpenedDatabase:db];
    if (result != SQLITE_OK) {
      MSLogError([MSAppCenter logTag], @"Could not change maximum database size to %ld bytes. SQLite error code: %i", sizeInBytes, result);
      success = NO;
    } else {
      long currentMaxPageCount = [MSDBStorage getMaxPageCountInOpenedDatabase:db];
      long actualMaxSize = currentMaxPageCount * self.pageSize;
      if (requestedMaxPageCount != currentMaxPageCount) {
        MSLogError([MSAppCenter logTag], @"Could not change maximum database size to %ld bytes, current maximum size is %ld bytes.",
                   sizeInBytes, actualMaxSize);
        success = NO;
      } else {
        if (sizeInBytes == actualMaxSize) {
          MSLogInfo([MSAppCenter logTag], @"Changed maximum database size to %ld bytes.", actualMaxSize);
        } else {
          MSLogInfo([MSAppCenter logTag], @"Changed maximum database size to %ld bytes (next multiple of 4KiB).", actualMaxSize);
        }
        self.maxSizeInBytes = actualMaxSize;
        success = YES;
      }
    }
  }
  sqlite3_close(db);
  if (completionHandler) {
    completionHandler(success);
  }
}

+ (sqlite3 *)openDatabaseAtFileURL:(NSURL *)fileURL withResult:(int *)result {
  sqlite3 *db = NULL;
  *result = sqlite3_open_v2([[fileURL absoluteString] UTF8String], &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_URI, NULL);
  if (*result != SQLITE_OK) {
    MSLogError([MSAppCenter logTag], @"Failed to open database with result: %d.", *result);
    return NULL;
  }
  return db;
}

+ (long)getPageSizeInOpenedDatabase:(void *)db {
  return [MSDBStorage querySingleValue:@"PRAGMA page_size;" inOpenedDatabase:db];
}

+ (long)getPageCountInOpenedDatabase:(void *)db {
  return [MSDBStorage querySingleValue:@"PRAGMA page_count;" inOpenedDatabase:db];
}

+ (long)getMaxPageCountInOpenedDatabase:(void *)db {
  return [MSDBStorage querySingleValue:@"PRAGMA max_page_count;" inOpenedDatabase:db];
}

+ (long)querySingleValue:(NSString *)query inOpenedDatabase:(void *)db {
  NSArray<NSArray *> *rows = [MSDBStorage executeSelectionQuery:query inOpenedDatabase:db withValues:nil];
  return rows.count > 0 && rows[0].count > 0 ? [(NSNumber *)rows[0][0] longValue] : 0;
}

+ (int)setMaxPageCount:(long)maxPageCount inOpenedDatabase:(void *)db {
  int result;
  NSString *statement = [NSString stringWithFormat:@"PRAGMA max_page_count = %ld", maxPageCount];

  // We use a selection query here because pragma set returns a value.
  [MSDBStorage executeSelectionQuery:statement inOpenedDatabase:db result:&result withValues:nil];
  return result;
}

+ (int)configureSQLite {
  return sqlite3_config(SQLITE_CONFIG_URI, 1);
}

@end
