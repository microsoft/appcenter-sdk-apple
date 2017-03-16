#import "MSDatabaseConnection.h"
#import "MSDBStorage.h"
#import "MSLogger.h"
#import "MSSqliteConnection.h"

static NSString *const kMSLogEntityName = @"MSDBLog";
static NSString *const kMSDBFileName = @"MSDBLogs.sqlite";
static NSString *const kMSLogTableName = @"MSLog";
static NSString *const kMSStorageKeyColumnName = @"storageKey";
static NSString *const kMSDataColumnName = @"data";

@interface MSDBStorage()

@property (nonatomic) id<MSDatabaseConnection> connection;

@end

@implementation MSDBStorage

@synthesize bucketFileCountLimit;
@synthesize bucketFileLogCountLimit;
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

-(void)initTables {
  NSString *createLogTableQuery = [NSString stringWithFormat:@"create table if not exists %@ (%@ text, %@ blob);",
                                   kMSLogTableName, kMSStorageKeyColumnName, kMSDataColumnName];
  [self.connection executeQuery:createLogTableQuery];
}

#pragma mark - Public

- (BOOL)saveLog:(id <MSLog>)log withStorageKey:(NSString *)storageKey {

  MSLogVerbose(@"DBStorage", @"saving log with storage key %@", storageKey);

  if (!log) {
    return NO;
  }

  NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
  NSString *base64Data = [logData base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength];

  MSLogVerbose(@"MSDBStorage", @"Saving base64String %@", base64Data);

  NSString *addLogQuery = [NSString stringWithFormat:@"insert or replace into %@ values ('%@', '%@')",
                                   kMSLogTableName, storageKey, base64Data];

  BOOL result = [self.connection executeQuery:addLogQuery];

  MSLogVerbose(@"DBStorage", @"Log has been saved successfully %d", result);

  return result;
}

- (NSArray <MSLog> *)deleteLogsForStorageKey:(NSString *)storageKey {
  NSArray<MSLog> *logs = [self getLogsWith:storageKey];
  [self deleteLogsWith:storageKey];
  return logs;
}

- (void)deleteLogsForId:(NSString *)logsId withStorageKey:(NSString *)storageKey {

  // FIXME: logsId ?
  [self deleteLogsWith:storageKey];
}

- (BOOL)loadLogsForStorageKey:(NSString *)storageKey withCompletion:(nullable MSLoadDataCompletionBlock)completion {
  NSArray<MSLog> *logs = [self getLogsWith:storageKey];

  if (completion) {

    // FIXME: batchId ?
    completion(logs.count > 0, logs, nil);
  }

  return logs.count > 0;
}

- (void)closeBatchWithStorageKey:(NSString *)storageKey {
  // TODO:
}

- (NSArray<MSLog>*) getLogsWith:(NSString*)storageKey {
  NSString *selectLogQuery = [NSString stringWithFormat:@"select * from %@ where %@ == '%@'",
                              kMSLogTableName, kMSStorageKeyColumnName, storageKey];
  NSArray<NSArray<NSString*>*> *result = [self.connection loadDataFromDB:selectLogQuery];
  NSMutableArray<MSLog> *logs = [NSMutableArray<MSLog> arrayWithCapacity:100];

  
  for (NSArray<NSString*> *row in result) {
    NSString *base64Data = row[1];
    NSData *rawData = [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    //
    MSLogVerbose(@"MSDBStorage", @"rawData not nil? %@", rawData != nil ? @"YES, not nil" : @"NO, it's nil");
    if(rawData) {
      MSLogVerbose(@"MSDBStorage", @"rawData: %@", rawData);
    }

    NSKeyedUnarchiver *un = [[NSKeyedUnarchiver alloc] initForReadingWithData:rawData];
    MSLogVerbose(@"MSDBStorage", @"un not nil? %@", un != nil ? @"YES, not nil" : @"NO, it's nil");


    NSDictionary<NSString *, id> *result2 =[un dictionaryWithValuesForKeys:row];
    MSLogVerbose(@"MSDBStorage", @"result2 not nil? %@", result2 != nil ? @"YES, not nil" : @"NO, it's nil");
    //
    id<MSLog> log = [NSKeyedUnarchiver unarchiveObjectWithData:rawData];

    MSLogVerbose(@"MSDBStorage", @"Restored log not nil? %@", log != nil ? @"YES, not nil" : @"NO, it's nil");

    [logs addObject:log];
  }
  return logs;
}

- (void) deleteLogsWith:(NSString*)storageKey {
  NSString *deleteLogQuery = [NSString stringWithFormat:@"delete from %@ where %@ == '%@'",
                              kMSLogTableName, kMSStorageKeyColumnName, storageKey];
  [self.connection executeQuery:deleteLogQuery];
}

@end
