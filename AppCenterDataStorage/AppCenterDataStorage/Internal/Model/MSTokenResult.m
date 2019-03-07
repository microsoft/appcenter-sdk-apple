#import "MSTokenResult.h"

@implementation MSTokenResult

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

- (instancetype)initWithString:(NSString *)tokenString{
    self = [super init];
    
    NSData* jsonData = [tokenString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    
    if(jsonData != nil && error == nil){
        
        // Create token result object.
        self = [[MSTokenResult alloc] initWithPartition:jsonDictionary[kMSPartition]
                                                     dbAccount:jsonDictionary[kMSDbAccount]
                                                        dbName:jsonDictionary[kMSDbName]
                                              dbCollectionName:jsonDictionary[kMSDbCollectionName]
                                                         token:jsonDictionary[kMSToken]
                                                        status:jsonDictionary[kMSStatus]
                                                     expiresOn:jsonDictionary[kMSExpiresOn]];
        return self;
    }
    
    return nil;
}


-(NSString *) serializeToString{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    
    if(jsonData != nil && error == nil){
        NSString *tokenString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        return tokenString;
    }
    
    return nil;
}

@end
