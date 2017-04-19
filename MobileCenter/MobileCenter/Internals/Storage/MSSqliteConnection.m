#import "MSSqliteConnection.h"
#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface MSSqliteConnection ()

@property(nonatomic, strong) NSString *documentsDirectory;
@property(nonatomic, strong) NSString *databaseFilename;
@property(nonatomic, strong) NSMutableArray<NSMutableArray<NSString *> *> *arrResults;
@property(nonatomic, strong) NSMutableArray *arrColumnNames;
@property(nonatomic) int affectedRows;
@property(nonatomic) long long lastInsertedRowID;

@end

@implementation MSSqliteConnection

@synthesize documentsDirectory;
@synthesize databaseFilename;

- (instancetype)initWithDatabaseFilename:(NSString *)dbFilename {
  self = [super init];
  if (self) {

    // Set the documents directory path to the documentsDirectory property.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.documentsDirectory = [paths objectAtIndex:0];

    // Keep the database filename.
    self.databaseFilename = dbFilename;

    // Copy the database file into the documents directory if necessary.
    [self copyDatabaseIntoDocumentsDirectory];
  }
  return self;
}

#pragma mark - Private

- (void)copyDatabaseIntoDocumentsDirectory {

  // Check if the database file exists in the documents directory.
  NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
  if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {

    // The database file does not exist in the documents directory, so copy it from the main bundle now.
    NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFilename];
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];

    // Check if any error occurred during copying and display it.
    if (error != nil) {
      NSLog(@"%@", [error localizedDescription]);
    }
  }
}

- (BOOL)runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable {

  // Total query result
  BOOL result = YES;

  // Create a sqlite object.
  sqlite3 *sqlite3Database;

  // Set the database file path.
  NSString *databasePath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];

  // TODO looks like we can optimize those 2 initializations.
  // Initialize the results array.
  if (self.arrResults != nil) {
    [self.arrResults removeAllObjects];
    self.arrResults = nil;
  }
  self.arrResults = [NSMutableArray<NSMutableArray<NSString *> *> new];

  // Initialize the column names array.
  if (self.arrColumnNames != nil) {
    [self.arrColumnNames removeAllObjects];
    self.arrColumnNames = nil;
  }
  self.arrColumnNames = [[NSMutableArray alloc] init];

  // Open the database.
  BOOL openDatabaseResult = (BOOL)sqlite3_open([databasePath UTF8String], &sqlite3Database);
  if (openDatabaseResult == SQLITE_OK) {

    // Declare a sqlite3_stmt object in which will be stored the query after having been compiled into a SQLite
    // statement.
    sqlite3_stmt *compiledStatement;

    // Load all data from database to memory.
    BOOL prepareStatementResult = (BOOL)sqlite3_prepare_v2(sqlite3Database, query, -1, &compiledStatement, NULL);
    if (prepareStatementResult == SQLITE_OK) {

      // Check if the query is non-executable.
      if (!queryExecutable) {

        // In this case data must be loaded from the database.

        // Declare an array to keep the data for each fetched row.
        NSMutableArray<NSString *> *arrDataRow;

        // Loop through the results and add them to the results array row by row.
        while (sqlite3_step(compiledStatement) == SQLITE_ROW) {

          // Initialize the mutable array that will contain the data of a fetched row.
          arrDataRow = [NSMutableArray new];

          // Get the total number of columns.
          unsigned int totalColumns = sqlite3_column_count(compiledStatement);

          // Go through all columns and fetch each column data.
          for (unsigned int i = 0; i < totalColumns; ++i) {

            // Convert the column data to text (characters).
            const char *dbDataAsChars = (const char *)sqlite3_column_text(compiledStatement, i);

            // If there are contents in the currenct column (field) then add them to the current row array.
            if (dbDataAsChars != NULL) {

              // Convert the characters to string.
              [arrDataRow addObject:[NSString stringWithUTF8String:dbDataAsChars]];
            }

            // Keep the current column name.
            if (self.arrColumnNames.count != totalColumns) {
              dbDataAsChars = sqlite3_column_name(compiledStatement, i);
              [self.arrColumnNames addObject:[NSString stringWithUTF8String:dbDataAsChars]];
            }
          }

          // Store each fetched data row in the results array, but first check if there is actually data.
          if (arrDataRow.count > 0) {
            [self.arrResults addObject:arrDataRow];
          }
        }
      } else {

        // This is the case of an executable query (insert, update, ...).

        // Execute the query.
        int executeQueryResults = sqlite3_step(compiledStatement);
        if (executeQueryResults == SQLITE_DONE) {

          // Keep the affected rows.
          self.affectedRows = sqlite3_changes(sqlite3Database);

          // Keep the last inserted row ID.
          self.lastInsertedRowID = sqlite3_last_insert_rowid(sqlite3Database);
        } else {

          // If could not execute the query show the error message on the debugger.
          NSLog(@"DB Error: %s\nerror code: %d", sqlite3_errmsg(sqlite3Database), executeQueryResults);
          result = NO;
        }
      }
    } else {

      // In the database cannot be opened then show the error message on the debugger.
      NSLog(@"DB Error: %s\nquery: %s", sqlite3_errmsg(sqlite3Database), query);
      result = NO;
    }

    // Release the compiled statement from memory.
    sqlite3_finalize(compiledStatement);
  } else {
    result = NO;
  }

  // Close the database.
  sqlite3_close(sqlite3Database);

  NSLog(@"Successfull query: %@", result ? @"YES" : @"NO");

  return result;
}

#pragma mark - Public method implementation

- (NSArray<NSArray<NSString *> *> *)loadDataFromDB:(NSString *)query {

  // Run the query and indicate that is not executable.
  // The query string is converted to a char* object.
  [self runQuery:[query UTF8String] isQueryExecutable:NO];

  // Returned the loaded results.
  return (NSArray<NSArray<NSString *> *> *)self.arrResults;
}

- (BOOL)executeQuery:(NSString *)query {

  // Run the query and indicate that is executable.
  return [self runQuery:[query UTF8String] isQueryExecutable:YES];
}

@end
