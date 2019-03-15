#import "MSTokenResult.h"
#import "MSDataStorageConstants.h"

@implementation MSTokenResult

static NSString *const kMSDbName = @"dbName";
static NSString *const kMSStatus = @"status";
static NSString *const kMSPartition = @"partition";
static NSString *const kMSDbAccount = @"dbAccount";
static NSString *const kMSDbCollectionName = @"dbCollectionName";
static NSString *const kMSExpiresOn = @"expiresOn";
static NSString *const kMSToken = @"token";

@synthesize partition = _partition;
@synthesize dbAccount = _dbAccount;
@synthesize dbName = _dbName;
@synthesize dbCollectionName = _dbCollectionName;
@synthesize token = _token;
@synthesize status = _status;
@synthesize expiresOn = _expiresOn;

- (instancetype)initWithPartition:(NSString *)partition
                        dbAccount:(NSString *)dbAccount
                           dbName:(NSString *)dbName
                 dbCollectionName:(NSString *)dbCollectionName
                            token:(NSString *)token
                           status:(NSString *)status
                        expiresOn:(NSString *)expiresOn {
  self = [super init];
  if (self) {
    _partition = partition;
    _dbAccount = dbAccount;
    _dbName = dbName;
    _dbCollectionName = dbCollectionName;
    _token = token;
    _status = status;
    _expiresOn = expiresOn;
  }
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)tokens {
  self = [super init];
  if (self) {
    self = [[MSTokenResult alloc] initWithPartition:tokens[kMSPartition]
                                          dbAccount:tokens[kMSDbAccount]
                                             dbName:tokens[kMSDbName]
                                   dbCollectionName:tokens[kMSDbCollectionName]
                                              token:tokens[kMSToken]
                                             status:tokens[kMSStatus]
                                          expiresOn:tokens[kMSExpiresOn]];
  }
  return self;
}

- (instancetype)initWithString:(NSString *)tokenString {
  self = [super init];
  if (self) {
    NSData *jsonData = [tokenString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    if (jsonData != nil && error == nil) {

      // Create token result object.
      self = [[MSTokenResult alloc] initWithPartition:jsonDictionary[kMSPartition]
                                            dbAccount:jsonDictionary[kMSDbAccount]
                                               dbName:jsonDictionary[kMSDbName]
                                     dbCollectionName:jsonDictionary[kMSDbCollectionName]
                                                token:jsonDictionary[kMSToken]
                                               status:jsonDictionary[kMSStatus]
                                            expiresOn:jsonDictionary[kMSExpiresOn]];
    }
  }
  return self;
}

- (NSDictionary *)convertToDictionary {
  return @{
    kMSPartition : self.partition,
    kMSDbAccount : self.dbAccount,
    kMSDbName : self.dbName,
    kMSDbCollectionName : self.dbCollectionName,
    kMSToken : self.token,
    kMSStatus : self.status,
    kMSExpiresOn : self.expiresOn,
  };
}

- (NSString *)serializeToString {
  NSError *error = nil;
  NSDictionary *tokenDict = [self convertToDictionary];
  if ([NSJSONSerialization isValidJSONObject:tokenDict]) {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tokenDict options:NSJSONWritingPrettyPrinted error:&error];
    if (jsonData != nil && error == nil) {
      return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
  }
  return nil;
}

@end
