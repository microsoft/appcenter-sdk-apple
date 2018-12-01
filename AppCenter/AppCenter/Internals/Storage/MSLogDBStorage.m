#import <sqlite3.h>

#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSDBStoragePrivate.h"
#import "MSLogDBStoragePrivate.h"
#import "MSLogDBStorageVersion.h"
#import "MSUtility+StringFormatting.h"

static const NSUInteger kMSSchemaVersion = 3;

@implementation MSLogDBStorage

#pragma mark - Initialization

- (instancetype)init {

  /*
   * DO NOT modify schema without a migration plan and bumping database version.
   */
  MSDBSchema *schema = @{
    kMSLogTableName : @[
      @{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
      @{kMSGroupIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
      @{kMSLogColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}, @{kMSTargetTokenColumnName : @[ kMSSQLiteTypeText ]},
      @{kMSTargetKeyColumnName : @[ kMSSQLiteTypeText ]}, @{kMSPriorityColumnName : @[ kMSSQLiteTypeInteger ]}
    ]
  };
  self = [super initWithSchema:schema version:kMSSchemaVersion filename:kMSDBFileName];
  if (self) {
    NSDictionary *columnIndexes = [MSDBStorage columnsIndexes:schema];
    _idColumnIndex = ((NSNumber *)columnIndexes[kMSLogTableName][kMSIdColumnName]).unsignedIntegerValue;
    _groupIdColumnIndex = ((NSNumber *)columnIndexes[kMSLogTableName][kMSGroupIdColumnName]).unsignedIntegerValue;
    _logColumnIndex = ((NSNumber *)columnIndexes[kMSLogTableName][kMSLogColumnName]).unsignedIntegerValue;
    _targetTokenColumnIndex = ((NSNumber *)columnIndexes[kMSLogTableName][kMSTargetTokenColumnName]).unsignedIntegerValue;
    _batches = [NSMutableDictionary<NSString *, NSArray<NSNumber *> *> new];
    _targetTokenEncrypter = [MSEncrypter new];
  }
  return self;
}

#pragma mark - Save logs

- (BOOL)saveLog:(id<MSLog>)log withGroupId:(NSString *)groupId flags:(MSFlags)flags {
  if (!log) {
    return NO;
  }
  MSFlags persistenceFlags = flags & kMSPersistenceFlagsMask;

  // Insert this log to the DB.
  NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
  NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
  NSString *addLogQuery = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") VALUES ('%@', '%@', '%u')",
                                                     kMSLogTableName, kMSGroupIdColumnName, kMSLogColumnName, kMSPriorityColumnName,
                                                     groupId, base64Data, (unsigned int)persistenceFlags];

  // Serialize target token.
  if ([(NSObject *)log isKindOfClass:[MSCommonSchemaLog class]]) {
    NSString *targetToken = [[log transmissionTargetTokens] anyObject];
    NSString *encryptedToken = [self.targetTokenEncrypter encryptString:targetToken];
    NSString *targetKey = [MSUtility targetKeyFromTargetToken:targetToken];
    addLogQuery =
        [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", "
                                   @"\"%@\", \"%@\", \"%@\") VALUES ('%@', '%@', '%@', %@, '%u')",
                                   kMSLogTableName, kMSGroupIdColumnName, kMSLogColumnName, kMSTargetTokenColumnName,
                                   kMSTargetKeyColumnName, kMSPriorityColumnName, groupId, base64Data, encryptedToken,
                                   targetKey ? [NSString stringWithFormat:@"'%@'", targetKey] : @"NULL", (unsigned int)persistenceFlags];
  }
  return [self executeQueryUsingBlock:^int(void *db) {
           // Check maximum size.
           NSUInteger maxSize = [MSDBStorage getMaxPageCountInOpenedDatabase:db] * self.pageSize;
           if (base64Data.length >= maxSize) {
             MSLogError([MSAppCenter logTag],
                        @"Log is too large (%tu bytes) to store in database. Current maximum database size is %tu bytes.",
                        base64Data.length, maxSize);
             return SQLITE_ERROR;
           }

           // Try to insert.
           int result = [MSDBStorage executeNonSelectionQuery:addLogQuery inOpenedDatabase:db];
           NSMutableArray<NSNumber *> *logsCanBeDeleted = nil;
           if (result == SQLITE_FULL) {

             // Selecting logs with equal or lower priority and ordering by priority then age.
             NSString *query = [NSString stringWithFormat:@"SELECT \"%@\" FROM \"%@\" WHERE \"%@\" <= %u ORDER BY \"%@\" ASC, \"%@\" ASC",
                                                          kMSIdColumnName, kMSLogTableName, kMSPriorityColumnName, (unsigned int)flags,
                                                          kMSPriorityColumnName, kMSIdColumnName];
             NSArray<NSArray *> *entries = [MSDBStorage executeSelectionQuery:query inOpenedDatabase:db];
             logsCanBeDeleted = [NSMutableArray new];
             for (NSMutableArray *row in entries) {
               [logsCanBeDeleted addObject:row[0]];
             }
           }

           // If the database is full, delete logs until there is room to add the log.
           long countOfLogsDeleted = 0;
           NSUInteger index = 0;
           while (result == SQLITE_FULL && index < [logsCanBeDeleted count]) {
             result = [MSLogDBStorage deleteLogsFromDBWithColumnValues:@[ logsCanBeDeleted[index] ]
                                                            columnName:kMSIdColumnName
                                                      inOpenedDatabase:db];
             if (result != SQLITE_OK) {
               break;
             }
             MSLogDebug([MSAppCenter logTag], @"Deleted a log with id %@ to store a new log.", logsCanBeDeleted[index]);
             ++countOfLogsDeleted;
             ++index;
             result = [MSDBStorage executeNonSelectionQuery:addLogQuery inOpenedDatabase:db];
           }
           if (countOfLogsDeleted > 0) {
             MSLogDebug([MSAppCenter logTag], @"Log storage was over capacity, %ld oldest log(s) with equal or lower priority deleted.",
                        (long)countOfLogsDeleted);
           }
           if (result == SQLITE_OK) {
             MSLogVerbose([MSAppCenter logTag], @"Log is stored with id: '%ld'", (long)sqlite3_last_insert_rowid(db));
           } else if (result == SQLITE_FULL && index == [logsCanBeDeleted count]) {
             MSLogError([MSAppCenter logTag], @"Storage is full and no logs with equal or lower priority exist; discarding the log.");
           }
           return result;
         }] == SQLITE_OK;
}

#pragma mark - Load logs

- (BOOL)loadLogsWithGroupId:(NSString *)groupId
                      limit:(NSUInteger)limit
         excludedTargetKeys:(nullable NSArray<NSString *> *)excludedTargetKeys
          completionHandler:(nullable MSLoadDataCompletionHandler)completionHandler {
  BOOL logsAvailable;
  BOOL moreLogsAvailable = NO;
  NSString *batchId;
  NSMutableArray<NSArray *> *logEntries;
  NSMutableArray<NSNumber *> *dbIds = [NSMutableArray<NSNumber *> new];
  NSMutableArray<id<MSLog>> *logs = [NSMutableArray<id<MSLog>> new];

  // Get ids from batches.
  NSMutableArray<NSNumber *> *idsInBatches = [NSMutableArray<NSNumber *> new];
  for (NSString *batchKey in [self.batches allKeys]) {
    if ([batchKey hasPrefix:groupId]) {
      [idsInBatches addObjectsFromArray:(NSArray<NSNumber *> * _Nonnull) self.batches[batchKey]];
    }
  }

  // Build the "WHERE" clause's conditions.
  NSMutableString *condition = [NSMutableString stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, groupId];

  // Filter out paused target keys.
  if (excludedTargetKeys.count > 0) {
    [condition appendFormat:@" AND \"%@\" NOT IN ('%@')", kMSTargetKeyColumnName, [excludedTargetKeys componentsJoinedByString:@"', '"]];
  }

  // Take only logs that are not already part of a batch.
  if (idsInBatches.count > 0) {
    [condition appendFormat:@" AND \"%@\" NOT IN (%@)", kMSIdColumnName, [idsInBatches componentsJoinedByString:@", "]];
  }

  // Build the "ORDER BY" clause's conditions.
  [condition appendFormat:@" ORDER BY \"%@\" DESC, \"%@\" ASC", kMSPriorityColumnName, kMSIdColumnName];

  /*
   * There is a need to determine if there will be more logs available than those under the limit. This is just about knowing if there is at
   * least 1 log above the limit.
   *
   * FIXME: We should simply use a count API from the consumer object instead of the "limit + 1" technique, it only requires 1 SQL request
   * instead of 2 for the count but it is a bit confusing and doesn't really fit a database storage.
   */
  [condition appendFormat:@" LIMIT %lu", (unsigned long)((limit < NSUIntegerMax) ? limit + 1 : limit)];

  // Get log entries from DB.
  logEntries = [[self logsWithCondition:condition] mutableCopy];

  // More logs available for the next batch, remove the log in excess for this batch.
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
    self.batches[[groupId stringByAppendingString:batchId]] = dbIds;
    MSLogVerbose([MSAppCenter logTag], @"Load log(s) with id(s) '%@' as batch Id:%@", [dbIds componentsJoinedByString:@"','"], batchId);
  }

  // Load completed.
  if (completionHandler) {
    completionHandler(logs, batchId);
  }

  // Return YES if more logs available.
  return moreLogsAvailable;
}

#pragma mark - Delete logs

- (NSArray<id<MSLog>> *)deleteLogsWithGroupId:(NSString *)groupId {
  NSArray<id<MSLog>> *logs = [self logsFromDBWithGroupId:groupId];

  // Delete logs.
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
  NSString *condition = [NSString stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, groupId];
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
  NSMutableString *query = [NSMutableString stringWithFormat:@"SELECT * FROM \"%@\"", kMSLogTableName];
  if (condition.length > 0) {
    [query appendFormat:@" WHERE %@", condition];
  }
  NSArray<NSArray *> *entries = [self executeSelectionQuery:query];

  // Get logs from DB.
  for (NSMutableArray *row in entries) {
    NSNumber *dbId = row[self.idColumnIndex];
    NSData *logData = [[NSData alloc] initWithBase64EncodedString:row[self.logColumnIndex]
                                                          options:NSDataBase64DecodingIgnoreUnknownCharacters];
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
      MSLogError([MSAppCenter logTag], @"Deserialization failed for log with Id %@: %@", dbId,
                 exception ? exception.reason : @"The log deserialized to NULL.");
      [self deleteLogFromDBWithId:dbId];
      continue;
    }

    // Deserialize target token.
    NSString *encryptedToken = row[self.targetTokenColumnIndex];
    if (![encryptedToken isKindOfClass:[NSNull class]]) {
      NSString *targetToken = [self.targetTokenEncrypter decryptString:encryptedToken];
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

- (void)deleteLogsFromDBWithColumnValue:(id)columnValue columnName:(NSString *)columnName {
  [self deleteLogsFromDBWithColumnValues:@[ columnValue ] columnName:columnName];
}

- (void)deleteLogsFromDBWithColumnValues:(NSArray *)columnValues columnName:(NSString *)columnName {
  [self executeQueryUsingBlock:^int(void *db) {
    return [MSLogDBStorage deleteLogsFromDBWithColumnValues:columnValues columnName:columnName inOpenedDatabase:db];
  }];
}

+ (int)deleteLogsFromDBWithColumnValues:(NSArray *)columnValues columnName:(NSString *)columnName inOpenedDatabase:(void *)db {
  NSString *deletionTrace = [NSString
      stringWithFormat:@"Deletion of log(s) by %@ with value(s) '%@'", columnName, [columnValues componentsJoinedByString:@"','"]];

  // Build up delete query.
  char surroundingChar = (char)(([(NSObject *)[columnValues firstObject] isKindOfClass:[NSString class]]) ? '\'' : '\0');
  NSString *valuesSeparation = [NSString stringWithFormat:@"%c, %c", surroundingChar, surroundingChar];
  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" IN (%c%@%c)", columnName, surroundingChar,
                                                        [columnValues componentsJoinedByString:valuesSeparation], surroundingChar];
  NSString *deleteLogsQuery = [NSString stringWithFormat:@"DELETE FROM \"%@\" WHERE %@", kMSLogTableName, whereCondition];

  // Execute.
  int result = [MSDBStorage executeNonSelectionQuery:deleteLogsQuery inOpenedDatabase:db];
  if (result == SQLITE_OK) {
    MSLogVerbose([MSAppCenter logTag], @"%@ %@", deletionTrace, @"succeeded.");
  } else {
    MSLogError([MSAppCenter logTag], @"%@ %@", deletionTrace, @"failed.");
  }
  return result;
}

#pragma mark - DB count

- (NSUInteger)countLogs {
  return [self countEntriesForTable:kMSLogTableName condition:nil];
}

#pragma mark - DB migration

- (void)createPriorityIndex:(void *)db {
  NSString *indexStatement = [NSString stringWithFormat:@"CREATE INDEX \"ix_%@_%@\" ON \"%@\" (\"%@\")", kMSLogTableName,
                                                        kMSPriorityColumnName, kMSLogTableName, kMSPriorityColumnName];
  [MSDBStorage executeNonSelectionQuery:indexStatement inOpenedDatabase:db];
}

- (void)customizeDatabase:(void *)db {
  [self createPriorityIndex:db];
}

/*
 * Migration process is implemented through database versioning.
 * After altering current schema, database version should be bumped and actions for migration should be implemented in this method.
 */
- (void)migrateDatabase:(void *)db fromVersion:(NSUInteger)version {
  if (version < kMSTargetTokenVersion) {
    NSString *migrationQuery = [NSString
        stringWithFormat:@"ALTER TABLE \"%@\" ADD COLUMN \"%@\" %@", kMSLogTableName, kMSTargetTokenColumnName, kMSSQLiteTypeText];
    [MSDBStorage executeNonSelectionQuery:migrationQuery inOpenedDatabase:db];
  }
  if (version < kMSTargetKeyVersion) {
    NSString *migrationQuery =
        [NSString stringWithFormat:@"ALTER TABLE \"%@\" ADD COLUMN \"%@\" %@", kMSLogTableName, kMSTargetKeyColumnName, kMSSQLiteTypeText];
    [MSDBStorage executeNonSelectionQuery:migrationQuery inOpenedDatabase:db];
  }
  if (version < kMSLogPersistencePriorityVersion) {

    // Integer type for flags is actually unsigned int, but SQL resolves UNSIGNED INTEGER to INTEGER anyways.
    NSString *migrationQuery =
        [NSString stringWithFormat:@"ALTER TABLE \"%@\" ADD COLUMN \"%@\" %@ DEFAULT %u", kMSLogTableName, kMSPriorityColumnName,
                                   kMSSQLiteTypeInteger, (unsigned int)MSFlagsPersistenceNormal];
    [MSDBStorage executeNonSelectionQuery:migrationQuery inOpenedDatabase:db];
    [self createPriorityIndex:db];
  }
}

@end
