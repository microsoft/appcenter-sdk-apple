#import "MSAppCenterInternal.h"
#import "MSCommonSchemaLog.h"
#import "MSDBStoragePrivate.h"
#import "MSKeychainUtil.h"
#import "MSLogDBStoragePrivate.h"
#import "MSLogger.h"
#import "MSUtility+StringFormatting.h"
#import "MSUtility.h"

static const NSUInteger kMSSchemaVersion = 1;

@implementation MSLogDBStorage

#pragma mark - Initialization

- (instancetype)init {

  /*
   * DO NOT modify schema without a migration plan and bumping database version.
   */
  MSDBSchema *schema = @{
    kMSLogTableName : @[
      @{
        kMSIdColumnName : @[
          kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey,
          kMSSQLiteConstraintAutoincrement
        ]
      },
      @{
        kMSGroupIdColumnName :
            @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]
      },
      @{kMSLogColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
      @{kMSTargetTokenColumnName : @[ kMSSQLiteTypeText ]}
    ]
  };
  self = [super initWithSchema:schema
                       version:kMSSchemaVersion
                      filename:kMSDBFileName];
  if (self) {
    NSDictionary *columnIndexes = [MSDBStorage columnsIndexes:schema];
    _idColumnIndex =
        ((NSNumber *)columnIndexes[kMSLogTableName][kMSIdColumnName])
            .unsignedIntegerValue;
    _groupIdColumnIndex =
        ((NSNumber *)columnIndexes[kMSLogTableName][kMSGroupIdColumnName])
            .unsignedIntegerValue;
    _logColumnIndex =
        ((NSNumber *)columnIndexes[kMSLogTableName][kMSLogColumnName])
            .unsignedIntegerValue;
    _targetTokenColumnIndex =
        ((NSNumber *)columnIndexes[kMSLogTableName][kMSTargetTokenColumnName])
            .unsignedIntegerValue;
    _capacity = NSUIntegerMax;
    _batches = [NSMutableDictionary<NSString *, NSArray<NSNumber *> *> new];
    _targetTokenEncrypter = [[MSEncrypter alloc] initWithDefaultKey];
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
  if ((self = [self init])) {
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
  NSString *base64Data = [logData
      base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
  NSString *addLogQuery =
      [NSString stringWithFormat:
                    @"INSERT INTO \"%@\" (\"%@\", \"%@\") VALUES ('%@', '%@')",
                    kMSLogTableName, kMSGroupIdColumnName, kMSLogColumnName,
                    groupId, base64Data];

  // Serialize target token.
  if ([(NSObject *)log isKindOfClass:[MSCommonSchemaLog class]]) {
    NSString *targetToken = [[log transmissionTargetTokens] anyObject];
    NSString *encryptedToken =
        [self.targetTokenEncrypter encryptString:targetToken];
    addLogQuery =
        [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", "
                                   @"\"%@\") VALUES ('%@', '%@', '%@')",
                                   kMSLogTableName, kMSGroupIdColumnName,
                                   kMSLogColumnName, kMSTargetTokenColumnName,
                                   groupId, base64Data, encryptedToken];
  }
  BOOL succeeded = [self executeNonSelectionQuery:addLogQuery];
  NSUInteger logCount = [self countLogs];

  // Max out DB.
  if (succeeded && logCount > self.capacity) {
    NSUInteger overflowCount = logCount - self.capacity;
    [self deleteOldestLogsWithCount:overflowCount];
    MSLogDebug([MSAppCenter logTag],
               @"Log storage was over capacity, %ld oldest log(s) deleted.",
               (long)overflowCount);
  }
  return succeeded;
}

#pragma mark - Load logs

- (BOOL)loadLogsWithGroupId:(NSString *)groupId
                      limit:(NSUInteger)limit
             withCompletion:(nullable MSLoadDataCompletionBlock)completion {
  BOOL logsAvailable = NO;
  BOOL moreLogsAvailable = NO;
  NSString *batchId;
  NSMutableArray<NSArray *> *logEntries;
  NSMutableArray<NSNumber *> *dbIds = [NSMutableArray<NSNumber *> new];
  NSMutableArray<id<MSLog>> *logs = [NSMutableArray<id<MSLog>> new];

  // Get ids from batches.
  NSMutableArray<NSNumber *> *idsInBatches = [NSMutableArray<NSNumber *> new];
  for (NSString *batchKey in [self.batches allKeys]) {
    if ([batchKey hasPrefix:groupId]) {
      [idsInBatches addObjectsFromArray:(NSArray<NSNumber *> * _Nonnull)
                                            self.batches[batchKey]];
    }
  }

  // Build the "WHERE" clause's condition.
  NSMutableString *condition = [NSMutableString
      stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, groupId];

  // Take only logs that are not already part of a batch.
  if (idsInBatches.count > 0) {
    [condition appendFormat:@" AND \"%@\" NOT IN (%@)", kMSIdColumnName,
                            [idsInBatches componentsJoinedByString:@", "]];
  }

  /*
   * There is a need to determine if there will be more logs available than
   * those under the limit. This is just about knowing if there is at least 1
   * log above the limit.
   *
   * FIXME: We should simply use a count API from the consumer object instead of
   * the "limit + 1" technique, it only requires 1 SQL request instead of 2 for
   * the count but it is a bit confusing and doesn't realy fit a database
   * storage.
   */
  [condition appendFormat:@" LIMIT %lu",
                          (unsigned long)((limit < NSUIntegerMax) ? limit + 1
                                                                  : limit)];

  // Get log entries from DB.
  logEntries = [[self logsWithCondition:condition] mutableCopy];

  // More logs available for the next batch, remove the log in excess for this
  // batch.
  if (logEntries.count > 0 && logEntries.count > limit) {
    [logEntries removeLastObject];
    moreLogsAvailable = YES;
  }

  // Get lists of logs and DB ids.
  for (NSArray *logEntry in logEntries) {
    [dbIds addObject:logEntry[self.idColumnIndex]];
    [logs addObject:logEntry[self.logColumnIndex]];
  }

  // Generate batch Id.
  logsAvailable = logEntries.count > 0;
  if (logsAvailable) {
    batchId = MS_UUID_STRING;
    [self.batches setObject:dbIds
                     forKey:[groupId stringByAppendingString:batchId]];
  }

  // Load completed.
  if (completion) {
    completion(logs, batchId);
  }

  // Return YES if more logs available.
  return moreLogsAvailable;
}

#pragma mark - Delete logs

- (NSArray<id<MSLog>> *)deleteLogsWithGroupId:(NSString *)groupId {
  NSArray<id<MSLog>> *logs = [self logsFromDBWithGroupId:groupId];

  // Delete logs
  [self deleteLogsFromDBWithColumnValue:groupId
                             columnName:kMSGroupIdColumnName];

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
  NSArray<NSNumber *> *ids = self.batches[batchIdKey];

  // Delete logs and associated batch.
  if (ids.count > 0) {
    [self deleteLogsFromDBWithColumnValues:ids columnName:kMSIdColumnName];
    [self.batches removeObjectForKey:batchIdKey];
  }
}

#pragma mark - DB selection

- (NSArray<id<MSLog>> *)logsFromDBWithGroupId:(NSString *)groupId {

  // Get log entries for the given group Id.
  NSString *condition = [NSString
      stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, groupId];
  NSArray<NSArray *> *logEntries = [self logsWithCondition:condition];

  // Get logs only.
  NSMutableArray<id<MSLog>> *logs = [NSMutableArray<id<MSLog>> new];
  for (NSArray *logEntry in logEntries) {
    [logs addObject:logEntry[self.logColumnIndex]];
  }
  return logs;
}

- (NSArray<NSArray *> *)logsWithCondition:(NSString *_Nullable)condition {
  NSMutableArray<NSArray *> *logEntries = [NSMutableArray<NSArray *> new];
  NSMutableString *query = [NSMutableString
      stringWithFormat:@"SELECT * FROM \"%@\"", kMSLogTableName];
  if (condition.length > 0) {
    [query appendFormat:@" WHERE %@", condition];
  }
  NSArray<NSArray *> *entries = [self executeSelectionQuery:query];

  // Get logs from DB.
  for (NSMutableArray *row in entries) {
    NSNumber *dbId = row[self.idColumnIndex];
    NSData *logData = [[NSData alloc]
        initWithBase64EncodedString:row[self.logColumnIndex]
                            options:
                                NSDataBase64DecodingIgnoreUnknownCharacters];
    id<MSLog> log;
    NSException *exception;

    // Deserialize the log.
    @try {
      log = [NSKeyedUnarchiver unarchiveObjectWithData:logData];
    } @catch (NSException *e) {
      exception = e;
    }
    if (!log || exception) {

      // The archived log is not valid.
      MSLogError([MSAppCenter logTag],
                 @"Deserialization failed for log with Id %@: %@", dbId,
                 exception ? exception.reason
                           : @"The log deserialized to NULL.");
      [self deleteLogFromDBWithId:dbId];
      continue;
    }

    // Deserialize target token.
    NSString *encryptedToken = row[self.targetTokenColumnIndex];
    if (![encryptedToken isKindOfClass:[NSNull class]]) {
      NSString *targetToken =
          [self.targetTokenEncrypter decryptString:encryptedToken];
      [log addTransmissionTargetToken:targetToken];
    }

    // Update with deserialized log.
    row[self.logColumnIndex] = log;
    [logEntries addObject:row];
  }
  return logEntries;
}

#pragma mark - DB deletion

- (void)deleteLogFromDBWithId:(NSNumber *)dbId {
  [self deleteLogsFromDBWithColumnValue:dbId columnName:kMSIdColumnName];
}

- (void)deleteLogsFromDBWithColumnValue:(id)columnValue
                             columnName:(NSString *)columnName {
  [self deleteLogsFromDBWithColumnValues:@[ columnValue ]
                              columnName:columnName];
}

- (void)deleteLogsFromDBWithColumnValues:(NSArray *)columnValues
                              columnName:(NSString *)columnName {
  NSString *deletionTrace = [NSString
      stringWithFormat:@"Deletion of log(s) by %@ with value(s) '%@'",
                       columnName,
                       [columnValues componentsJoinedByString:@"','"]];

  // Build up delete query.
  char surroundingChar =
      ([(NSObject *)[columnValues firstObject] isKindOfClass:[NSString class]])
          ? '\''
          : '\0';
  NSString *valuesSeparation =
      [NSString stringWithFormat:@"%c, %c", surroundingChar, surroundingChar];
  NSString *whereCondition = [NSString
      stringWithFormat:@"\"%@\" IN (%c%@%c)", columnName, surroundingChar,
                       [columnValues componentsJoinedByString:valuesSeparation],
                       surroundingChar];
  NSString *deleteLogsQuery =
      [NSString stringWithFormat:@"DELETE FROM \"%@\" WHERE %@",
                                 kMSLogTableName, whereCondition];

  // Execute.
  if ([self executeNonSelectionQuery:deleteLogsQuery]) {
    MSLogVerbose([MSAppCenter logTag], @"%@ %@", deletionTrace, @"succeeded.");
  } else {
    MSLogError([MSAppCenter logTag], @"%@ %@", deletionTrace, @"failed.");
  }
}

- (void)deleteOldestLogsWithCount:(NSInteger)count {
  NSString *deleteLogQuery = [NSString
      stringWithFormat:@"DELETE FROM \"%@\" ORDER BY \"%@\" ASC LIMIT %ld",
                       kMSLogTableName, kMSIdColumnName, (long)count];
  [self executeNonSelectionQuery:deleteLogQuery];
}

#pragma mark - DB count

- (NSUInteger)countLogs {
  return [self countEntriesForTable:kMSLogTableName condition:nil];
}

#pragma mark - DB migration

/*
 * Migration process is implemented through database versioning.
 * After altering current schema, database version should be bumped and
 * actions for migration should be implemented in this method.
 */
- (void)migrateDatabase:(void *)db fromVersion:(NSUInteger)version {
  if (version < 1) {
    NSString *migrationQuery =
        [NSString stringWithFormat:@"ALTER TABLE \"%@\" ADD COLUMN \"%@\" TEXT",
                                   kMSLogTableName, kMSTargetTokenColumnName];
    [MSDBStorage executeNonSelectionQuery:migrationQuery inOpenedDatabase:db];
  }
}

@end
