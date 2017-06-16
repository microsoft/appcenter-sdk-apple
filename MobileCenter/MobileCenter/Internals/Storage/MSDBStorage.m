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
    _capacity = NSUIntegerMax;

    // Create the DB.
    NSString *createLogTableQuery =
        [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER PRIMARY KEY AUTOINCREMENT, %@ TEXT NOT "
                                   @"NULL, %@ TEXT NOT NULL, %@ TEXT);",
                                   kMSLogTableName, kMSIdColumnName, kMSGroupIdColumnName, kMSDataColumnName, kMSBatchIdColumnName];
    [self.connection executeQuery:createLogTableQuery];
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
  self = [self init];
  if (self) {
    _capacity = capacity;
  }
  return self;
}

#pragma mark - Save logs

- (BOOL)saveLog:(id<MSLog>)log withGroupId:(NSString *)groupId {
  if (!log) {
    return NO;
  }

  // Insert this log to the DB.
  NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
  NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
  NSString *addLogQuery =
      [NSString stringWithFormat:@"INSERT INTO %@ ('%@', '%@', '%@') VALUES ('%@', '%@', '%@')", kMSLogTableName,
                                 kMSGroupIdColumnName, kMSDataColumnName, kMSBatchIdColumnName, groupId, base64Data, @""];
  BOOL succeeded = [self.connection executeQuery:addLogQuery];
  NSUInteger logCount = [self countLogsWithGroupId:groupId];

  // Max out DB.
  if (succeeded && logCount > self.capacity) {
    NSUInteger overflowCount = logCount - self.capacity;
    [self deleteOldestLogsWithGroupId:groupId count:overflowCount];
    MSLogDebug([MSMobileCenter logTag], @"Log storage was over capacity, %ld oldest log(s) deleted.",
               (long)overflowCount);
  }
  return succeeded;
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
    
    // Update the logs in the DB with the batchId
    NSString *logIdsForBatch = [[logs allKeys] componentsJoinedByString:@"','"];
    
    NSString *updateLogsQuery = [NSString stringWithFormat:@"UPDATE %@ SET %@ = '%@' WHERE %@ IN ('%@')", kMSLogTableName, kMSBatchIdColumnName, batchId, kMSIdColumnName, logIdsForBatch];
    BOOL succeeded = [self.connection executeQuery:updateLogsQuery];
    if(succeeded) {
      MSLogDebug([MSMobileCenter logTag], @"Successfully updated logs with batchId %@", batchId);
    }
    else {
      MSLogError([MSMobileCenter logTag], @"Failed to update logs with batchId %@", batchId);
    }
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
  return logs;
}

- (void)deleteLogsWithBatchId:(NSString *)batchId {

  // Delete logs.
  if (batchId) {
    [self deleteLogsFromDBWithColumnValue:batchId columnName:kMSBatchIdColumnName];
  }
}

#pragma mark - DB selection

- (NSDictionary<NSString *, id<MSLog>> *)getLogsFromDBWithGroupId:(NSString *)groupId {
  NSString *selectLogQuery =
      [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ == '%@'", kMSLogTableName, kMSGroupIdColumnName, groupId];
  return [self getLogsFromDBWithQuery:selectLogQuery];
}

- (NSDictionary<NSString *, id<MSLog>> *)getLogsFromDBWithGroupId:(NSString *)groupId limit:(NSUInteger)limit {

  // Get logs from DB that are not already part of a batch.
  NSString *selectLogQuery =
      [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ == '%@' AND %@ == '' LIMIT %lu", kMSLogTableName,
                                 kMSGroupIdColumnName, groupId, kMSBatchIdColumnName, (unsigned long)limit];
  return [self getLogsFromDBWithQuery:selectLogQuery];
}

- (NSDictionary<NSString *, id<MSLog>> *)getLogsFromDBWithQuery:(NSString *)query {
  NSArray<NSArray<NSString *> *> *result = [self.connection selectDataFromDB:query];
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
    MSLogVerbose([MSMobileCenter logTag], @"%@ %@", deletionTrace, @"succeeded");
  } else {
    MSLogError([MSMobileCenter logTag], @"%@ %@", deletionTrace, @"failed");
  }
}

- (void)deleteOldestLogsWithGroupId:(NSString *)groupId count:(NSInteger)count {
  NSString *deleteLogQuery =
      [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = '%@' ORDER BY %@ ASC LIMIT %ld", kMSLogTableName,
                                 kMSGroupIdColumnName, groupId, kMSIdColumnName, (long)count];
  [self.connection executeQuery:deleteLogQuery];
}

#pragma mark - DB count

- (NSUInteger)countLogsWithGroupId:(NSString *)groupId {
  NSString *countLogQuery = [NSString
      stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@ = '%@'", kMSLogTableName, kMSGroupIdColumnName, groupId];
  NSArray<NSArray<NSString *> *> *result = [self.connection selectDataFromDB:countLogQuery];
  NSNumberFormatter *formatter = [NSNumberFormatter new];
  formatter.numberStyle = NSNumberFormatterDecimalStyle;
  return [formatter numberFromString:result[0][0]].unsignedIntegerValue;
}

@end
