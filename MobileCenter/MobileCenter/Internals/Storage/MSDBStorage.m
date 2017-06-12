#import "MSDBStoragePrivate.h"
#import "MSDatabaseConnection.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSSqliteConnection.h"
#import "MSUtility.h"

@implementation MSDBStorage

#pragma mark - Initialization

- (instancetype)init {
  self = [super init];
  if (self) {
    _connection = [[MSSqliteConnection alloc] initWithDatabaseFilename:kMSDBFileName];
    _batches = [NSMutableDictionary<NSString *, NSArray<NSString *> *> new];
    [self initTables];
  }
  return self;
}

- (void)initTables {
  NSString *createLogTableQuery = [NSString
      stringWithFormat:
          @"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER PRIMARY KEY AUTOINCREMENT, %@ TEXT NOT NULL, %@ TEXT NOT NULL);",
          kMSLogTableName, kMSIdColumnName, kMSGroupIdColumnName, kMSDataColumnName];
  [self.connection executeQuery:createLogTableQuery];
}

#pragma mark - Save logs

- (BOOL)saveLog:(id<MSLog>)log withGroupId:(NSString *)groupId {
  if (!log) {
    return NO;
  }
  NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
  NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
  NSString *addLogQuery =
      [NSString stringWithFormat:@"INSERT INTO %@ ('%@', '%@') VALUES ('%@', '%@')", kMSLogTableName,
                                 kMSGroupIdColumnName, kMSDataColumnName, groupId, base64Data];
  return [self.connection executeQuery:addLogQuery];
}

#pragma mark - Load logs

- (BOOL)loadLogsWithGroupId:(NSString *)groupId
                      limit:(NSUInteger)limit
             withCompletion:(nullable MSLoadDataCompletionBlock)completion {

  /*
   * There is a need to determine if there will be more logs available than those under the limit.
   * This is just about knowing if there is at least 1 log above the limit.
   */
  NSMutableDictionary<NSString *, id<MSLog>> *logs =
      [[self getLogsFromDBWithGroupId:groupId limit:(limit + 1)] mutableCopy];
  BOOL logsAvailable = NO;
  BOOL moreLogsAvailable = NO;
  NSString *batchId;

  // More logs available for the next batch, remove the log in excess for this batch.
  if (logs.count > 0 && logs.count > limit) {
    [logs removeObjectForKey:(NSString * _Nonnull)[[logs allKeys] lastObject]];
    moreLogsAvailable = YES;
  }

  // Generate batch Id.
  logsAvailable = logs.count > 0;
  if (logsAvailable) {
    batchId = MS_UUID_STRING;
    [self.batches setObject:(NSArray<NSString *> * _Nonnull)[logs allKeys]
                     forKey:[groupId stringByAppendingString:batchId]];
  }

  // Load completed.
  if (completion) {
    completion([logs allValues], batchId);
  }

  // Return YES if more logs available.
  return moreLogsAvailable;
}

#pragma mark - Delete logs

- (NSArray<id<MSLog>> *)deleteLogsWithGroupId:(NSString *)groupId {
  NSArray<id<MSLog>> *logs = [[self getLogsFromDBWithGroupId:groupId] allValues];

  // Delete logs
  [self deleteLogsFromDBWithColumnValue:groupId columnName:kMSGroupIdColumnName];

  // Delete related batches.
  for (NSString *batchKey in [self.batches allKeys]) {
    if ([batchKey hasPrefix:groupId]) {
      [self.batches removeObjectForKey:batchKey];
    }
  }
  return logs;
}

- (void)deleteLogsWithBatchId:(NSString *)batchId groupId:(NSString *)groupId {

  // Get log Ids.
  NSString *batchIdKey = [groupId stringByAppendingString:batchId];
  NSArray<NSString *> *Ids = self.batches[batchIdKey];

  // Delete logs and associated batch.
  if (Ids.count > 0) {
    [self deleteLogsFromDBWithColumnValues:Ids columnName:kMSIdColumnName];
    [self.batches removeObjectForKey:batchIdKey];
  }
}

#pragma mark - DB selection

- (NSDictionary<NSString *, id<MSLog>> *)getLogsFromDBWithGroupId:(NSString *)groupId {
  NSString *selectLogQuery =
      [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ == '%@'", kMSLogTableName, kMSGroupIdColumnName, groupId];
  return [self getLogsFromDBWithQuery:selectLogQuery];
}

- (NSDictionary<NSString *, id<MSLog>> *)getLogsFromDBWithGroupId:(NSString *)groupId limit:(NSUInteger)limit {
  NSString *selectLogQuery = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ == '%@' LIMIT %lu", kMSLogTableName,
                                                        kMSGroupIdColumnName, groupId, (unsigned long)limit];
  return [self getLogsFromDBWithQuery:selectLogQuery];
}

- (NSDictionary<NSString *, id<MSLog>> *)getLogsFromDBWithQuery:(NSString *)query {
  NSArray<NSArray<NSString *> *> *result = [self.connection loadDataFromDB:query];
  NSMutableDictionary<NSString *, id<MSLog>> *logs = [NSMutableDictionary<NSString *, id<MSLog>> new];

  // Get logs from DB.
  for (NSArray<NSString *> *row in result) {

    // TODO use constants for DB column indexes.
    NSString *Id = row[0];
    NSString *base64Data = row[2];
    NSData *logData =
        [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    id<MSLog> log;

    // Deserialize the log.
    @try {
      log = [NSKeyedUnarchiver unarchiveObjectWithData:logData];
    } @catch (NSException *exception) {

      // The archived log is not valid.
      MSLogError([MSMobileCenter logTag], @"Deserialization failed for log with Id %@: %@", Id, exception);
      [self deleteLogFromDBWithId:Id];
      continue;
    }
    [logs setObject:log forKey:Id];
  }
  return logs;
}

#pragma mark - DB deletion

- (void)deleteLogFromDBWithId:(NSString *)Id {
  [self deleteLogsFromDBWithColumnValue:Id columnName:kMSIdColumnName];
}

- (void)deleteLogsFromDBWithColumnValue:(NSString *)columnValue columnName:(NSString *)columnName {
  [self deleteLogsFromDBWithColumnValues:@[ columnValue ] columnName:columnName];
}

- (void)deleteLogsFromDBWithColumnValues:(NSArray<NSString *> *)columnValues columnName:(NSString *)columnName {
  NSString *deletionTrace = [NSString stringWithFormat:@"Deletion of log(s) by %@ with value(s) '%@'", columnName,
                                                       [columnValues componentsJoinedByString:@"','"]];

  // Build up delete query.
  NSString *deleteLogsQuery = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN ('%@')", kMSLogTableName,
                                                         columnName, [columnValues componentsJoinedByString:@"','"]];

  // Execute.
  if ([self.connection executeQuery:deleteLogsQuery]) {
    MSLogVerbose([MSMobileCenter logTag], @"%@ %@", deletionTrace, @"succeded");
  } else {
    MSLogError([MSMobileCenter logTag], @"%@ %@", deletionTrace, @"failed");
  }
}

@end
