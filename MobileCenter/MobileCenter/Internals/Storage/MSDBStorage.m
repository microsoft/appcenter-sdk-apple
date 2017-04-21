#import "MSDBStoragePrivate.h"
#import "MSDatabaseConnection.h"
#import "MSLogger.h"
#import "MSSqliteConnection.h"

static NSString *const kMSLogEntityName = @"MSDBLog";
static NSString *const kMSDBFileName = @"MSDBLogs.sqlite";
static NSString *const kMSLogTableName = @"MSLog";
static NSString *const kMSGroupIDColumnName = @"groupID";
static NSString *const kMSDataColumnName = @"data";

@implementation MSDBStorage

@synthesize connection;

#pragma mark - Initialization

- (instancetype)init {
  self = [super init];
  if (self) {
    self.connection = [[MSSqliteConnection alloc] initWithDatabaseFilename:kMSDBFileName];
    [self initTables];
  }
  return self;
}

- (void)initTables {
  NSString *createLogTableQuery = [NSString stringWithFormat:@"create table if not exists %@ (%@ text, %@ text);",
                                                             kMSLogTableName, kMSGroupIDColumnName, kMSDataColumnName];
  [self.connection executeQuery:createLogTableQuery];
}

#pragma mark - Public

- (BOOL)saveLog:(id<MSLog>)log withGroupID:(NSString *)groupID {
  if (!log) {
    return NO;
  }
  NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
  NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
  NSString *addLogQuery = [NSString
      stringWithFormat:@"insert or replace into %@ values ('%@', '%@')", kMSLogTableName, groupID, base64Data];
  return [self.connection executeQuery:addLogQuery];
}

- (NSArray<MSLog> *)deleteLogsForGroupID:(NSString *)groupID {
  NSArray<MSLog> *logs = [self getLogsWithGroupID:groupID];
  [self deleteLogsWithGroupID:groupID];
  return logs;
}

- (void)deleteLogsForId:(__attribute__((unused)) NSString *)batchId withGroupID:(NSString *)groupID {

  // FIXME: Restore batch deletion.
  [self deleteLogsWithGroupID:groupID];
}

- (BOOL)loadLogsForGroupID:(NSString *)groupID
                     limit:(NSUInteger)limit
            withCompletion:(nullable MSLoadDataCompletionBlock)completion {

  /*
   * There is a need to determine if there will be more logs available than those under the limit.
   * So this is just about knowing if there is at least 1 log above the limit.
   * Thus, just 1 log is added to the requested limit and then removed later as needed.
   */
  NSMutableArray<MSLog> *logs = (NSMutableArray<MSLog> *)[self getLogsWithGroupID:groupID limit:(limit + 1)];
  BOOL moreLogsAvailable = NO;

  // Remove the log in excess, it means there is more logs available.
  if (logs.count > limit) {
    [logs removeLastObject];
    moreLogsAvailable = YES;
  }
  if (completion) {
    completion(logs.count > 0, logs, groupID);
  }

  // Return YES if more logs available.
  return moreLogsAvailable;
}

#pragma mark - Private

- (NSArray<MSLog> *)getLogsWithGroupID:(NSString *)groupID {
  NSString *selectLogQuery =
      [NSString stringWithFormat:@"select * from %@ where %@ == '%@'", kMSLogTableName, kMSGroupIDColumnName, groupID];
  return [self getLogsWithQwery:selectLogQuery];
}

- (NSArray<MSLog> *)getLogsWithGroupID:(NSString *)groupID limit:(NSUInteger)limit {
  NSString *selectLogQuery = [NSString stringWithFormat:@"select * from %@ where %@ == '%@' limit %lu", kMSLogTableName,
                                                        kMSGroupIDColumnName, groupID, (unsigned long)limit];
  return [self getLogsWithQwery:selectLogQuery];
}

- (NSArray<MSLog> *)getLogsWithQwery:(NSString *)qwery {
  NSArray<NSArray<NSString *> *> *result = [self.connection loadDataFromDB:qwery];
  NSMutableArray<MSLog> *logs = [NSMutableArray<MSLog> new];

  // Deserialize logs from DB.
  for (NSArray<NSString *> *row in result) {
    NSString *base64Data = row[1];
    NSData *logData =
        [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    id<MSLog> log = [NSKeyedUnarchiver unarchiveObjectWithData:logData];
    [logs addObject:log];
  }
  return logs;
}

- (void)deleteLogsWithGroupID:(NSString *)groupID {
  NSString *deleteLogQuery =
      [NSString stringWithFormat:@"delete from %@ where %@ == '%@'", kMSLogTableName, kMSGroupIDColumnName, groupID];
  [self.connection executeQuery:deleteLogQuery];
}

@end
