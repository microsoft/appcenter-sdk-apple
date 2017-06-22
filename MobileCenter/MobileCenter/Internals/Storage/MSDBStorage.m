
                                                    
#import <sqlite3.h>

#import "MSDBStoragePrivate.h"
#import "MSMobileCenterInternal.h"
#import "MSStorage.h"
#import "MSUtility+File.h"

@implementation MSDBStorage

- (instancetype)initWithSchema:(MSDBSchema *)schema filename:(NSString *)filename {
  if ((self = [super init])) {
    NSMutableArray *tableQueries = [NSMutableArray new];
    NSMutableDictionary *dbColumnsIndexes = [NSMutableDictionary new];

    // Path to the database.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                                   inDomains:NSUserDomainMask] lastObject];
    if (appSupportURL) {
      NSURL *fileURL =
          [appSupportURL URLByAppendingPathComponent:[kMSStorageDirectory stringByAppendingPathComponent:filename]];
      [MSUtility createFileAtURL:fileURL];
      _filePath = fileURL.absoluteString;
    }

    // Browse tables.
    for (NSString *tableName in schema) {
      NSMutableDictionary *tableColumnsIndexes = [NSMutableDictionary new];
      NSMutableArray *columnQueries = [NSMutableArray new];
      NSArray<NSDictionary *> *columns = schema[tableName];

      // Optimization, don't even compute the query if the table already exists.
      BOOL tableDontExist = ![self tableExists:tableName];

      // Browse columns.
      for (NSUInteger i = 0; i < columns.count; i++) {
        NSString *columnName = columns[i].allKeys[0];
        [tableColumnsIndexes setObject:@(i) forKey:columnName];

        // Compute column query.
        if (tableDontExist) {
          [columnQueries addObject:[NSString stringWithFormat:@"\"%@\" %@", columnName,
                                                              [columns[i][columnName] componentsJoinedByString:@" "]]];
        }
      }

      // Compute table query.
      if (tableDontExist) {
        [tableQueries addObject:[NSString stringWithFormat:@"CREATE TABLE \"%@\" (%@);", tableName,
                                                           [columnQueries componentsJoinedByString:@", "]]];
      }
      [dbColumnsIndexes setObject:tableColumnsIndexes forKey:tableName];
    }

    // Create the DB.
    if (tableQueries.count > 0) {
      NSString *createTablesQuery = [tableQueries componentsJoinedByString:@"; "];
      [self executeNonSelectionQuery:createTablesQuery];
    }

    // Keep collected indexes.
    _columnIndexes = dbColumnsIndexes;
  }
  return self;
}

- (BOOL)tableExists:(NSString *)tableName {
  NSString *query = [NSString
      stringWithFormat:@"SELECT COUNT(*) FROM \"sqlite_master\" WHERE \"type\"='table' AND \"name\"='%@';", tableName];
  NSArray *result = [self executeSelectionQuery:query];
  return (result.count > 0) ? [result[0][0] boolValue] : NO;
}

- (NSUInteger)countEntriesForTable:(NSString *)tableName condition:(nullable NSString *)condition {
  NSMutableString *countLogQuery = [NSMutableString stringWithFormat:@"SELECT COUNT(*) FROM \"%@\" ", tableName];
  if (condition.length > 0) {
    [countLogQuery appendFormat:@"WHERE %@", condition];
  }
  NSArray<NSArray<NSNumber *> *> *result = [self executeSelectionQuery:countLogQuery];
  return (result.count > 0) ? result[0][0].unsignedIntegerValue : 0;
}

- (BOOL)executeNonSelectionQuery:(NSString *)query {
  sqlite3 *db = NULL;
  int result = SQLITE_OK;
  result = sqlite3_open_v2([self.filePath UTF8String], &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
  if (result == SQLITE_OK) {
    char *errMsg;
    result = sqlite3_exec(db, [query UTF8String], NULL, NULL, &errMsg);
    if (result != SQLITE_OK) {
      MSLogError([MSMobileCenter logTag], @"Query \"%@\" failed with error: %d - %@", query, result,
                 [[NSString alloc] initWithUTF8String:errMsg]);
    }
  } else {
    MSLogError([MSMobileCenter logTag], @"Failed to open database.");
  }
  sqlite3_close(db);
  return SQLITE_OK == result;
}

- (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query {
  NSMutableArray<NSMutableArray *> *entries = [[NSMutableArray<NSMutableArray *> alloc] init];
  sqlite3 *db = NULL;
  sqlite3_stmt *statement = NULL;
  int result = 0;
  result = sqlite3_open_v2([self.filePath UTF8String], &db, SQLITE_OPEN_READONLY, NULL);
  if (result == SQLITE_OK) {
    result = sqlite3_prepare_v2(db, [query UTF8String], -1, &statement, NULL);
    if (result == SQLITE_OK) {
      // Loop on rows.
      while (sqlite3_step(statement) == SQLITE_ROW) {
        NSMutableArray *entry = [NSMutableArray new];

        // Loop on columns.
        for (int i = 0; i < sqlite3_column_count(statement); i++) {
          id value = nil;

          // Convert values.
          switch (sqlite3_column_type(statement, i)) {
          case SQLITE_INTEGER:
            value = [NSNumber numberWithInteger:sqlite3_column_int(statement, i)];
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
        [entries addObject:entry];
      }
      sqlite3_finalize(statement);
    } else {
      MSLogError([MSMobileCenter logTag], @"Query \"%@\" failed with error: %d - %@", query, result,
                 [[NSString alloc] initWithUTF8String:sqlite3_errstr(result)]);
    }
  } else {
    MSLogError([MSMobileCenter logTag], @"Failed to open database.");
  }
  sqlite3_close(db);
  return entries;
}

- (void)deleteDB {
  if (self.filePath.length > 0) {
    [MSUtility removeItemAtURL:[NSURL URLWithString:(NSString * _Nonnull)self.filePath]];
  }
}
@end
