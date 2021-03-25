// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

//#import <sqlite3.h>

#import "MSACAppCenterInternal.h"
#import "MSACDBStoragePrivate.h"
#import "MSACStorageBindableArray.h"
#import "MSACUtility+File.h"

static dispatch_once_t sqliteConfigurationResultOnceToken;
//static int sqliteConfigurationResult = 1;

@implementation MSACDBStorage

+ (void)load {

  /*
   * Configure SQLite at load time to invoke configuration only once and before opening a DB.
   * If it is custom SQLite library we need to turn on URI filename capability.
   */
//  sqliteConfigurationResult = [self configureSQLite];
}

- (instancetype)initWithSchema:(MSACDBSchema *)schema version:(NSUInteger)version filename:(NSString *)filename {
  _schema = schema;

  // Log SQLite configuration result only once at init time because log level won't be set at load time.
  dispatch_once(&sqliteConfigurationResultOnceToken, ^{
//    if (sqliteConfigurationResult == SQLITE_OK) {
//      MSACLogDebug([MSACAppCenter logTag], @"SQLite global configuration successfully updated.");
//    } else {
//      NSString *errorString;
//      if (@available(macOS 10.10, *)) {
//        errorString = [NSString stringWithUTF8String:sqlite3_errstr(sqliteConfigurationResult)];
//      } else {
//        errorString = @(sqliteConfigurationResult).stringValue;
//      }
//      MSACLogError([MSACAppCenter logTag], @"Failed to update SQLite global configuration. Error: %@.", errorString);
//    }
  });
  if ((self = [super init])) {
//    int result = [self configureDatabaseWithSchema:schema version:version filename:filename];
//    if (result == SQLITE_CORRUPT || result == SQLITE_NOTADB) {
//      [self dropDatabase];
//      result = [self configureDatabaseWithSchema:schema version:version filename:filename];
//    }
//    if (result != SQLITE_OK) {
//      MSACLogError([MSACAppCenter logTag], @"Failed to initialize database.");
//    }
  }
  return self;
}

- (instancetype)initWithVersion:(NSUInteger)version filename:(NSString *)filename {
  return [self initWithSchema:nil version:version filename:filename];
}

- (int)configureDatabaseWithSchema:(MSACDBSchema *)schema version:(NSUInteger)version filename:(NSString *)filename {
//  BOOL newDatabase = ![MSACUtility fileExistsForPathComponent:filename];
//  self.dbFileURL = [MSACUtility createFileAtPathComponent:filename withData:nil atomically:NO forceOverwrite:NO];
//  self.maxSizeInBytes = kMSACDefaultDatabaseSizeInBytes;
//  int result;
//  sqlite3 *db = [MSACDBStorage openDatabaseAtFileURL:self.dbFileURL withResult:&result];
//  if (result != SQLITE_OK) {
//    return result;
//  }
//  self.pageSize = [MSACDBStorage getPageSizeInOpenedDatabase:db];
//  if (self.pageSize == 0) {
//    MSACLogError([MSACAppCenter logTag], @"Failed to get storage page size.");
//    sqlite3_close(db);
//    return SQLITE_ERROR;
//  }
//  NSUInteger databaseVersion = [MSACDBStorage versionInOpenedDatabase:db result:&result];
//  if (result != SQLITE_OK) {
//    sqlite3_close(db);
//    return result;
//  }
//
//  // Create table.
//  if (schema) {
//    result = [MSACDBStorage createTablesWithSchema:schema inOpenedDatabase:db];
//    if (result != SQLITE_OK) {
//      MSACLogError([MSACAppCenter logTag], @"Failed to create tables with schema with error \"%d\".", result);
//      sqlite3_close(db);
//      return result;
//    }
//  }
//  if (newDatabase) {
//    MSACLogInfo([MSACAppCenter logTag], @"Created \"%@\" database with %lu version.", filename, (unsigned long)version);
//    [self customizeDatabase:db];
//  } else if (databaseVersion < version) {
//    MSACLogInfo([MSACAppCenter logTag], @"Migrating \"%@\" database from version %lu to %lu.", filename, (unsigned long)databaseVersion,
//                (unsigned long)version);
//    [self migrateDatabase:db fromVersion:databaseVersion];
//  }
//  [MSACDBStorage enableAutoVacuumInOpenedDatabase:db];
//  [MSACDBStorage setVersion:version inOpenedDatabase:db];
//  sqlite3_close(db);
  return 0;
}

- (int)executeQueryUsingBlock:(MSACDBStorageQueryBlock)callback {
//  int result;
//  sqlite3 *db = [MSACDBStorage openDatabaseAtFileURL:self.dbFileURL withResult:&result];
//  if (!db) {
//    return result;
//  }
//  if (self.pageSize == 0) {
//    MSACLogError([MSACAppCenter logTag], @"The database was not configured correctly. The page size is expected to be non zero.");
//    sqlite3_close(db);
//    return SQLITE_ERROR;
//  }
//
//  // The value is stored as part of the database connection and must be reset every time the database is opened.
//  long maxPageCount = self.maxSizeInBytes / self.pageSize;
//  result = [MSACDBStorage setMaxPageCount:maxPageCount inOpenedDatabase:db];
//
//  // Do not proceed with the query if the database is corrupted.
//  if (result == SQLITE_CORRUPT || result == SQLITE_NOTADB) {
//    sqlite3_close(db);
//    return result;
//  }
//
//  // Log a warning if max page count can't be set.
//  if (result != SQLITE_OK) {
//    MSACLogError([MSACAppCenter logTag], @"Failed to open database with specified maximum size constraint.");
//  }
//  result = callback(db);
//  sqlite3_close(db);
  return 0;
}

- (void)dropDatabase {
  BOOL result = [MSACUtility deleteFileAtURL:self.dbFileURL];
  if (result) {
    MSACLogVerbose([MSACAppCenter logTag], @"Database %@ has been deleted.", (NSString * _Nonnull) self.dbFileURL.absoluteString);
  } else {
    MSACLogError([MSACAppCenter logTag], @"Failed to delete database.");
  }
}

- (BOOL)dropTable:(NSString *)tableName {
    return true;
}

- (BOOL)createTable:(NSString *)tableName columnsSchema:(MSACDBColumnsSchema *)columnsSchema {
    return true;
}

+ (NSString *)columnsQueryFromColumnsSchema:(MSACDBColumnsSchema *)columnsSchema {
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

+ (int)createTablesWithSchema:(MSACDBSchema *)schema inOpenedDatabase:(void *)db {
    return true;
}

+ (NSDictionary *)columnsIndexes:(MSACDBSchema *)schema {
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
  return [MSACDBStorage tableExists:tableName inOpenedDatabase:db result:nil];
}

+ (BOOL)tableExists:(NSString *)tableName inOpenedDatabase:(void *)db result:(int *)result {
  MSACStorageBindableArray *values = [MSACStorageBindableArray new];
  [values addString:tableName];
  NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM \"sqlite_master\" WHERE \"type\"='table' AND \"name\"=?;"];
  NSArray<NSArray *> *entries = [MSACDBStorage executeSelectionQuery:query inOpenedDatabase:db result:result withValues:values];
  return entries.count > 0 && entries[0].count > 0 ? [(NSNumber *)entries[0][0] boolValue] : NO;
}

+ (NSUInteger)versionInOpenedDatabase:(void *)db result:(int *)result {
  NSArray<NSArray *> *entries = [MSACDBStorage executeSelectionQuery:@"PRAGMA user_version"
                                                    inOpenedDatabase:db
                                                              result:result
                                                          withValues:nil];
  return entries.count > 0 && entries[0].count > 0 ? [(NSNumber *)entries[0][0] unsignedIntegerValue] : 0;
}

+ (void)setVersion:(NSUInteger)version inOpenedDatabase:(void *)db {
  NSString *query = [NSString stringWithFormat:@"PRAGMA user_version = %lu", (unsigned long)version];

  // We use a selection query here because pragma set returns a value.
  [MSACDBStorage executeSelectionQuery:query inOpenedDatabase:db withValues:nil];
}

+ (void)enableAutoVacuumInOpenedDatabase:(void *)db {
  NSArray<NSArray *> *result = [MSACDBStorage executeSelectionQuery:@"PRAGMA auto_vacuum" inOpenedDatabase:db withValues:nil];
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
    MSACLogDebug([MSACAppCenter logTag], @"Vacuuming database and enabling auto_vacuum");

    // We use a selection query here because pragma set returns a value.
    [MSACDBStorage executeSelectionQuery:@"PRAGMA auto_vacuum = FULL;" inOpenedDatabase:db withValues:nil];
    [MSACDBStorage executeSelectionQuery:@"VACUUM;" inOpenedDatabase:db withValues:nil];
  }
}

- (NSUInteger)countEntriesForTable:(NSString *)tableName
                         condition:(nullable NSString *)condition
                        withValues:(nullable MSACStorageBindableArray *)values {
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

- (int)executeNonSelectionQuery:(NSString *)query withValues:(nullable MSACStorageBindableArray *)values {
  return [self executeQueryUsingBlock:^int(void *db) {
    return [MSACDBStorage executeNonSelectionQuery:query inOpenedDatabase:db withValues:values];
  }];
}

+ (int)executeNonSelectionQuery:(NSString *)query inOpenedDatabase:(void *)db withValues:(nullable MSACStorageBindableArray *)values {
    return 0;
}

+ (int)executeQuery:(NSString *)query
    inOpenedDatabase:(void *)db
          withValues:(nullable MSACStorageBindableArray *)values
          usingBlock:(MSACDBStorageQueryBlock)block {
    return 0;
}

- (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query withValues:(nullable MSACStorageBindableArray *)values {
  __block NSArray<NSArray *> *entries = nil;
  [self executeQueryUsingBlock:^int(void *db) {
    entries = [MSACDBStorage executeSelectionQuery:query inOpenedDatabase:db withValues:values];
    return 0;
  }];
  return entries ?: [NSArray<NSArray *> new];
}

+ (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query
                             inOpenedDatabase:(void *)db
                                   withValues:(nullable MSACStorageBindableArray *)values {
  return [self executeSelectionQuery:query inOpenedDatabase:db result:nil withValues:values];
}

+ (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query
                             inOpenedDatabase:(void *)db
                                       result:(int *)result
                                   withValues:(nullable MSACStorageBindableArray *)values {
  NSMutableArray<NSMutableArray *> *entries = [NSMutableArray<NSMutableArray *> new];
  return entries;
}

//+ (NSObject *)columnValueFromStatement:(sqlite3_stmt *)statement atIndex:(int)index {
//
//  /*
//   * Convert values.
//   */
//  int columnType = sqlite3_column_type(statement, index);
//  switch (columnType) {
//  case SQLITE_INTEGER:
//    return @(sqlite3_column_int(statement, index));
//  case SQLITE_TEXT:
//    return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, index)];
//  case SQLITE_NULL:
//    return [NSNull null];
//  default:
//    MSACLogError([MSACAppCenter logTag], @"Could not retrieve column value at index %d from statement: unknown type %d.", index,
//                 columnType);
//    return [NSNull null];
//  }
//}

- (void)customizeDatabase:(void *)__unused db {
}

- (void)migrateDatabase:(void *)__unused db fromVersion:(NSUInteger)__unused version {
}

- (void)setMaxStorageSize:(long)sizeInBytes completionHandler:(nullable void (^)(BOOL))completionHandler {
}

+ (long)getPageSizeInOpenedDatabase:(void *)db {
  return [MSACDBStorage querySingleValue:@"PRAGMA page_size;" inOpenedDatabase:db];
}

+ (long)getPageCountInOpenedDatabase:(void *)db {
  return [MSACDBStorage querySingleValue:@"PRAGMA page_count;" inOpenedDatabase:db];
}

+ (long)getMaxPageCountInOpenedDatabase:(void *)db {
  return [MSACDBStorage querySingleValue:@"PRAGMA max_page_count;" inOpenedDatabase:db];
}

+ (long)querySingleValue:(NSString *)query inOpenedDatabase:(void *)db {
  NSArray<NSArray *> *rows = [MSACDBStorage executeSelectionQuery:query inOpenedDatabase:db withValues:nil];
  return rows.count > 0 && rows[0].count > 0 ? [(NSNumber *)rows[0][0] longValue] : 0;
}

+ (int)setMaxPageCount:(long)maxPageCount inOpenedDatabase:(void *)db {
  int result;
  NSString *statement = [NSString stringWithFormat:@"PRAGMA max_page_count = %ld", maxPageCount];

  // We use a selection query here because pragma set returns a value.
  [MSACDBStorage executeSelectionQuery:statement inOpenedDatabase:db result:&result withValues:nil];
  return result;
}

+ (int)configureSQLite {
    return 0;
}

@end
