#import <sqlite3.h>

#import "MSAppCenterInternal.h"
#import "MSDBStoragePrivate.h"
#import "MSStorage.h"
#import "MSUtility+File.h"

@implementation MSDBStorage

- (instancetype)initWithSchema:(MSDBSchema *)schema
                       version:(NSUInteger)version
                      filename:(NSString *)filename {
  if ((self = [super init])) {

    // Path to the database.
    _dbFileURL = [MSUtility createFileAtPathComponent:filename
                                             withData:nil
                                           atomically:NO
                                       forceOverwrite:NO];

    // If it is custom SQLite library we need to turn on URI filename
    // capability.
    sqlite3_config(SQLITE_CONFIG_URI, 1);

    // Execute all initialize operation with one database instance.
    [self executeQueryUsingBlock:^int(void *db) {

      // Create tables based on schema.
      NSUInteger tablesCreated =
          [MSDBStorage createTablesWithSchema:schema inOpenedDatabase:db];
      BOOL newDatabase = tablesCreated == schema.count;
      NSUInteger databaseVersion = [MSDBStorage versionInOpenedDatabase:db];
      if (databaseVersion < version && !newDatabase) {
        MSLogInfo([MSAppCenter logTag],
                  @"Migrate \"%@\" database from %lu to %lu version.", filename,
                  (unsigned long)databaseVersion, (unsigned long)version);
        [self migrateDatabase:db fromVersion:databaseVersion];
      }
      [MSDBStorage setVersion:version inOpenedDatabase:db];
      return SQLITE_OK;
    }];
  }
  return self;
}

- (BOOL)executeQueryUsingBlock:(MSDBStorageQueryBlock)callback {
  sqlite3 *db = NULL;
  int result = SQLITE_OK;
  result = sqlite3_open_v2(
      [[self.dbFileURL absoluteString] UTF8String], &db,
      SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_URI, NULL);
  if (result == SQLITE_OK) {
    result = callback(db);
  } else {
    MSLogError([MSAppCenter logTag],
               @"Failed to open database with result: %d.", result);
  }
  sqlite3_close(db);
  return SQLITE_OK == result;
}

+ (NSUInteger)createTablesWithSchema:(MSDBSchema *)schema
                    inOpenedDatabase:(void *)db {
  NSMutableArray *tableQueries = [NSMutableArray new];

  // Browse tables.
  for (NSString *tableName in schema) {

    // Optimization, don't even compute the query if the table already exists.
    if ([self tableExists:tableName inOpenedDatabase:db]) {
      continue;
    }
    NSMutableArray *columnQueries = [NSMutableArray new];
    NSArray<NSDictionary<NSString *, NSArray<NSString *> *> *> *columns =
        schema[tableName];

    // Browse columns.
    for (NSUInteger i = 0; i < columns.count; i++) {
      NSString *columnName = columns[i].allKeys[0];

      // Compute column query.
      [columnQueries
          addObject:[NSString
                        stringWithFormat:@"\"%@\" %@", columnName,
                                         [columns[i][columnName]
                                             componentsJoinedByString:@" "]]];
    }

    // Compute table query.
    [tableQueries
        addObject:[NSString
                      stringWithFormat:@"CREATE TABLE \"%@\" (%@);", tableName,
                                       [columnQueries
                                           componentsJoinedByString:@", "]]];
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
      [tableColumnsIndexes setObject:@(i) forKey:columnName];
    }
    [dbColumnsIndexes setObject:tableColumnsIndexes forKey:tableName];
  }
  return dbColumnsIndexes;
}

+ (BOOL)tableExists:(NSString *)tableName inOpenedDatabase:(void *)db {
  NSString *query =
      [NSString stringWithFormat:@"SELECT COUNT(*) FROM \"sqlite_master\" "
                                 @"WHERE \"type\"='table' AND \"name\"='%@';",
                                 tableName];
  NSArray<NSArray *> *result =
      [MSDBStorage executeSelectionQuery:query inOpenedDatabase:db];
  return (result.count > 0) ? [(NSNumber *)result[0][0] boolValue] : NO;
}

+ (NSUInteger)versionInOpenedDatabase:(void *)db {
  NSArray<NSArray *> *result =
      [MSDBStorage executeSelectionQuery:@"PRAGMA user_version"
                        inOpenedDatabase:db];
  return (result.count > 0) ? [(NSNumber *)result[0][0] unsignedIntegerValue]
                            : 0;
}

+ (void)setVersion:(NSUInteger)version inOpenedDatabase:(void *)db {
  NSString *query = [NSString
      stringWithFormat:@"PRAGMA user_version = %lu", (unsigned long)version];
  [MSDBStorage executeNonSelectionQuery:query inOpenedDatabase:db];
}

- (NSUInteger)countEntriesForTable:(NSString *)tableName
                         condition:(nullable NSString *)condition {
  NSMutableString *countLogQuery = [NSMutableString
      stringWithFormat:@"SELECT COUNT(*) FROM \"%@\" ", tableName];
  if (condition.length > 0) {
    [countLogQuery appendFormat:@"WHERE %@", condition];
  }
  NSArray<NSArray<NSNumber *> *> *result =
      [self executeSelectionQuery:countLogQuery];
  return (result.count > 0) ? result[0][0].unsignedIntegerValue : 0;
}

- (BOOL)executeNonSelectionQuery:(NSString *)query {
  return [self executeQueryUsingBlock:^int(void *db) {
    return [MSDBStorage executeNonSelectionQuery:query inOpenedDatabase:db];
  }];
}

+ (int)executeNonSelectionQuery:(NSString *)query inOpenedDatabase:(void *)db {
  char *errMsg;
  int result = sqlite3_exec(db, [query UTF8String], NULL, NULL, &errMsg);
  if (result != SQLITE_OK) {
    MSLogError([MSAppCenter logTag], @"Query \"%@\" failed with error: %d - %@",
               query, result, [[NSString alloc] initWithUTF8String:errMsg]);
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

+ (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query
                             inOpenedDatabase:(void *)db {
  NSMutableArray<NSMutableArray *> *entries =
      [NSMutableArray<NSMutableArray *> new];
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
          value = [NSNumber numberWithInteger:sqlite3_column_int(statement, i)];
          break;
        case SQLITE_TEXT:
          value = [NSString
              stringWithUTF8String:(const char *)sqlite3_column_text(statement,
                                                                     i)];
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
    MSLogError([MSAppCenter logTag], @"Query \"%@\" failed with error: %d - %@",
               query, result,
               [[NSString alloc] initWithUTF8String:sqlite3_errmsg(db)]);
  }
  return entries;
}

- (void)deleteDatabase {
  if (self.dbFileURL) {
    [MSUtility deleteFileAtURL:self.dbFileURL];
  }
}

- (void)migrateDatabase:(void *)__unused db
            fromVersion:(NSUInteger)__unused version {
}

@end
