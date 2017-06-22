#import <sqlite3.h>

#import "MSDBStoragePrivate.h"
#import "MSMobileCenterInternal.h"
#import "MSStorage.h"
#import "MSUtility+File.h"

@implementation MSDBStorage

- (instancetype)initWithSchema:(MSDBSchema *)schema filename:(NSString *)filename {
  if ((self = [super init])) {
    NSMutableArray *tableQueries = [NSMutableArray new];

    // Path to the database.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                                   inDomains:NSUserDomainMask] lastObject];
    if (appSupportURL) {
      NSURL *fileURL =
          [appSupportURL URLByAppendingPathComponent:[kMSStorageDirectory stringByAppendingPathComponent:filename]];
      [MSUtility createFileAtURL:fileURL];
      _filePath = fileURL.absoluteString;
    }

    // Flatten tables.
    for (NSString *tableName in schema) {

      // Don't even compute the query if the table doesn't exist.
      if (![self tableExists:tableName]) {
        NSMutableArray *columnQueries = [NSMutableArray new];

        // Flatten columns.
        for (NSDictionary *column in schema[tableName]) {
          NSString *columnName = column.allKeys[0];
          [columnQueries addObject:[NSString stringWithFormat:@"\"%@\" %@", columnName,
                                                              [column[columnName] componentsJoinedByString:@" "]]];
        }
        [tableQueries addObject:[NSString stringWithFormat:@"CREATE TABLE \"%@\" (%@);", tableName,
                                                           [columnQueries componentsJoinedByString:@", "]]];
      }
    }

    // Create the DB.
    if (tableQueries.count > 0) {
      NSString *createTablesQuery = [tableQueries componentsJoinedByString:@"; "];
      [self executeNonSelectionQuery:createTablesQuery];
    }
  }
  return self;
}

- (BOOL)tableExists:(NSString *)tableName {
  NSString *query = [NSString
      stringWithFormat:@"SELECT COUNT(*) FROM \"sqlite_master\" WHERE \"type\"='table' AND \"name\"='%@';", tableName];
  NSArray *result = [self executeSelectionQuery:query];
  return (result.count > 0) ? [result[0][0] boolValue] : NO;
}

- (NSUInteger)countEntriesForTable:(NSString *)tableName where:(nullable NSString *)condition {
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
    sqlite3_close(db);
  } else {
    sqlite3_close(db);
    MSLogError([MSMobileCenter logTag], @"Failed to open database.");
  }
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
    sqlite3_close(db);
  } else {
    sqlite3_close(db);
    MSLogError([MSMobileCenter logTag], @"Failed to open database.");
  }
  return entries;
}

- (void)deleteDB {
  if (self.filePath.length > 0) {
    [MSUtility removeItemAtURL:[NSURL URLWithString:(NSString * _Nonnull)self.filePath]];
  }
}
@end
