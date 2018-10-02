#import <sqlite3.h>

#import "MSAppCenterInternal.h"
#import "MSDBStoragePrivate.h"
#import "MSUtility+File.h"

@implementation MSDBStorage

- (instancetype)initWithSchema:(MSDBSchema *)schema version:(NSUInteger)version filename:(NSString *)filename{
  if ((self = [super init])) {
    _dbFileURL = [MSUtility createFileAtPathComponent:filename withData:nil atomically:NO forceOverwrite:NO];
    _maxPageCount = [MSDBStorage numberOfPagesInBytes:kMSDefaultDatabaseSizeInBytes];

    // If it is custom SQLite library we need to turn on URI filename
    // capability.
    sqlite3_config(SQLITE_CONFIG_URI, 1);

    // Execute all initialize operation with one database instance.
    [self executeQueryUsingBlock:^int(void *db) {

      // Create tables based on schema.
      NSUInteger tablesCreated = [MSDBStorage createTablesWithSchema:schema inOpenedDatabase:db];
      BOOL newDatabase = tablesCreated == schema.count;
      NSUInteger databaseVersion = [MSDBStorage versionInOpenedDatabase:db];
      if (databaseVersion < version && !newDatabase) {
        MSLogInfo([MSAppCenter logTag], @"Migrate \"%@\" database from %lu to %lu version.", filename,
                  (unsigned long)databaseVersion, (unsigned long)version);
        [self migrateDatabase:db fromVersion:databaseVersion];
      }
      [MSDBStorage enableAutoVacuumInOpenedDatabase:db];
      [MSDBStorage setVersion:version inOpenedDatabase:db];
      return SQLITE_OK;
    }];
  }
  return self;
}

- (int)executeQueryUsingBlock:(MSDBStorageQueryBlock)callback {
  int result;
  sqlite3 *db = [self openDatabaseAtFileURL:self.dbFileURL withMaxPageCount:self.maxPageCount withResult:&result];
  if (!db) {
    return result;
  }
  result = callback(db);
  sqlite3_close(db);
  return result;
}

+ (NSUInteger)createTablesWithSchema:(MSDBSchema *)schema inOpenedDatabase:(void *)db {
  NSMutableArray *tableQueries = [NSMutableArray new];

  // Browse tables.
  for (NSString *tableName in schema) {

    // Optimization, don't even compute the query if the table already exists.
    if ([self tableExists:tableName inOpenedDatabase:db]) {
      continue;
    }
    NSMutableArray *columnQueries = [NSMutableArray new];
    NSArray<NSDictionary<NSString *, NSArray<NSString *> *> *> *columns = schema[tableName];

    // Browse columns.
    for (NSUInteger i = 0; i < columns.count; i++) {
      NSString *columnName = columns[i].allKeys[0];

      // Compute column query.
      [columnQueries addObject:[NSString stringWithFormat:@"\"%@\" %@", columnName,
                                                          [columns[i][columnName] componentsJoinedByString:@" "]]];
    }

    // Compute table query.
    [tableQueries addObject:[NSString stringWithFormat:@"CREATE TABLE \"%@\" (%@);", tableName,
                                                       [columnQueries componentsJoinedByString:@", "]]];
  }

  // Create the tables.
  if (tableQueries.count > 0) {
    NSString *createTablesQuery = [tableQueries componentsJoinedByString:@"; "];
    [self executeNonSelectionQuery:createTablesQuery inOpenedDatabase:db];
  }
  return tableQueries.count;
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
  NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM \"sqlite_master\" "
                                               @"WHERE \"type\"='table' AND \"name\"='%@';",
                                               tableName];
  NSArray<NSArray *> *result = [MSDBStorage executeSelectionQuery:query inOpenedDatabase:db];
  return (result.count > 0) ? [(NSNumber *)result[0][0] boolValue] : NO;
}

+ (NSUInteger)versionInOpenedDatabase:(void *)db {
  NSArray<NSArray *> *result = [MSDBStorage executeSelectionQuery:@"PRAGMA user_version" inOpenedDatabase:db];
  return (result.count > 0) ? [(NSNumber *)result[0][0] unsignedIntegerValue] : 0;
}

+ (void)setVersion:(NSUInteger)version inOpenedDatabase:(void *)db {
  NSString *query = [NSString stringWithFormat:@"PRAGMA user_version = %lu", (unsigned long)version];
  [MSDBStorage executeNonSelectionQuery:query inOpenedDatabase:db];
}

+ (void)enableAutoVacuumInOpenedDatabase:(void *)db {
  NSArray<NSArray *> *result = [MSDBStorage executeSelectionQuery:@"PRAGMA auto_vacuum" inOpenedDatabase:db];
  int vacuumMode = [(NSNumber *)result[0][0] intValue];
  BOOL autoVacuumDisabled = vacuumMode == 0;
  [MSDBStorage executeNonSelectionQuery:@"PRAGMA auto_vacuum = FULL;" inOpenedDatabase:db];
  if (autoVacuumDisabled) {
    MSLogDebug([MSAppCenter logTag], @"Vacuuming database to enable auto_vacuum");
    [MSDBStorage executeNonSelectionQuery:@"VACUUM" inOpenedDatabase:db];
  }
}

- (NSUInteger)countEntriesForTable:(NSString *)tableName condition:(nullable NSString *)condition {
  NSMutableString *countLogQuery = [NSMutableString stringWithFormat:@"SELECT COUNT(*) FROM \"%@\" ", tableName];
  if (condition.length > 0) {
    [countLogQuery appendFormat:@"WHERE %@", condition];
  }
  NSArray<NSArray<NSNumber *> *> *result = [self executeSelectionQuery:countLogQuery];
  return (result.count > 0) ? result[0][0].unsignedIntegerValue : 0;
}

- (int)executeNonSelectionQuery:(NSString *)query {
  return [self executeQueryUsingBlock:^int(void *db) {
    return [MSDBStorage executeNonSelectionQuery:query inOpenedDatabase:db];
  }];
}

+ (int)executeNonSelectionQuery:(NSString *)query inOpenedDatabase:(void *)db {
  char *errMsg;
  int result = sqlite3_exec(db, [query UTF8String], NULL, NULL, &errMsg);
  if (result != SQLITE_OK) {
    MSLogError([MSAppCenter logTag], @"Query \"%@\" failed with error: %d - %@", query, result,
               [[NSString alloc] initWithUTF8String:errMsg]);
  }
  return result;
}

- (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query {
  __block NSArray<NSArray *> *entries = nil;
  [self executeQueryUsingBlock:^int(void *db) {
    entries = [MSDBStorage executeSelectionQuery:query inOpenedDatabase:db];
    return SQLITE_OK;
  }];
  return entries ?: [NSArray<NSArray *> new];
}

+ (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query inOpenedDatabase:(void *)db {
  NSMutableArray<NSMutableArray *> *entries = [NSMutableArray<NSMutableArray *> new];
  sqlite3_stmt *statement = NULL;
  int result = sqlite3_prepare_v2(db, [query UTF8String], -1, &statement, NULL);
  if (result == SQLITE_OK) {

    // Loop on rows.
    while (sqlite3_step(statement) == SQLITE_ROW) {
      NSMutableArray *entry = [NSMutableArray new];

      // Loop on columns.
      for (int i = 0; i < sqlite3_column_count(statement); i++) {
        id value = nil;

        /*
         * Convert values.
         * TODO: Add here any other type it needs.
         */
        switch (sqlite3_column_type(statement, i)) {
        case SQLITE_INTEGER:
          value = @(sqlite3_column_int(statement, i));
          break;
        case SQLITE_TEXT:
          value = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, i)];
          break;
        default:
          value = [NSNull null];
          break;
        }
        [entry addObject:value];
      }
      if (entry.count > 0) {
        [entries addObject:entry];
      }
    }
    sqlite3_finalize(statement);
  } else {
    MSLogError([MSAppCenter logTag], @"Query \"%@\" failed with error: %d - %@", query, result,
               [[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]);
  }
  return entries;
}

- (void)migrateDatabase:(void *)__unused db fromVersion:(NSUInteger)__unused version {
}

- (void)setMaxStorageSize:(long)sizeInBytes completionHandler:(nullable void (^)(BOOL))completionHandler {

  // Check the current number of pages in the database to determine whether the requested size will shrink the database.
  NSArray<NSArray *> *rows = [self executeSelectionQuery:@"PRAGMA page_count;"];
  int currentPageCount = [(NSNumber *)rows[0][0] intValue];
  MSLogDebug([MSAppCenter logTag], @"Found %i pages in the database.", currentPageCount);
  int requestedMaxPageCount = [MSDBStorage numberOfPagesInBytes:sizeInBytes];
  if (currentPageCount > requestedMaxPageCount) {
    MSLogWarning([MSAppCenter logTag], @"Cannot change database size to %ld bytes as it would cause a loss of data. "
                                       "Maximum database size will not be changed.",
                 sizeInBytes);
    if (completionHandler) {
      completionHandler(NO);
    }
    return;
  }

  // Attempt to open the database with the given limit and check the page count to make sure the given limit works.
  int result;
  BOOL success;
  sqlite3 *db = [self openDatabaseAtFileURL:self.dbFileURL withMaxPageCount:requestedMaxPageCount withResult:&result];
  if (result != SQLITE_OK) {
    MSLogError([MSAppCenter logTag], @"Could not change maximum database size to %ld bytes. SQLite error "
                                       "code: %i", sizeInBytes, result);
    success = NO;
  } else {
    rows = [MSDBStorage executeSelectionQuery:@"PRAGMA max_page_count;" inOpenedDatabase:db];
    int currentMaxPageCount = [(NSNumber *)rows[0][0] intValue];
    long actualSize = requestedMaxPageCount * kMSDefaultPageSizeInBytes;
    if (requestedMaxPageCount != currentMaxPageCount) {
      MSLogError([MSAppCenter logTag], @"Could not change maximum database size to %ld bytes, "
                 @"current maximum size is %ld bytes.", sizeInBytes, actualSize);
      success = NO;
    } else {
      if (sizeInBytes == actualSize) {
        MSLogInfo([MSAppCenter logTag], @"Changed maximum database size to %ld bytes.", actualSize);
      } else {
        MSLogInfo([MSAppCenter logTag], @"Changed maximum database size to %ld bytes (next multiple of 4KiB).",
                  actualSize);
      }
      self.maxPageCount = requestedMaxPageCount;
      success = YES;
    }
  }
  if (completionHandler) {
    completionHandler(success);
  }
  sqlite3_close(db);
}

- (sqlite3 *)openDatabaseAtFileURL:(NSURL *)fileURL withMaxPageCount:(int)maxPageCount withResult:(int *)result {
  sqlite3 *db = NULL;
  *result = sqlite3_open_v2([[fileURL absoluteString] UTF8String], &db,
                            SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_URI, NULL);
  if (*result != SQLITE_OK) {
    MSLogError([MSAppCenter logTag], @"Failed to open database with result: %d.", *result);
    return NULL;
  }
  NSString *statement = [NSString stringWithFormat:@"PRAGMA max_page_count = %i;", maxPageCount];
  char *errorMessage;
  *result = sqlite3_exec(db, [statement UTF8String], NULL, NULL, &errorMessage);
  if (*result != SQLITE_OK) {
    errorMessage = errorMessage ? errorMessage : "(nil)";
    NSString *printableErrorMessage = [NSString stringWithCString:errorMessage encoding:NSUTF8StringEncoding];
    MSLogError([MSAppCenter logTag], @"Failed to open database with specified maximum size constraint. Error message:"
                                     " %@", printableErrorMessage);
  }
  return db;
}

+ (int)numberOfPagesInBytes:(long)bytes {
  return (int)(ceil((double)bytes / (double)kMSDefaultPageSizeInBytes));
}

@end
