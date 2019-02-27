#import <Foundation/Foundation.h>
#import "MSTokenResult.h"

@implementation MSTokenResult

@synthesize partition = _partition;
@synthesize dbAccount = _dbAccount;
@synthesize dbName = _dbName;
@synthesize dbCollectionName = _dbCollectionName;
@synthesize token = _token;
@synthesize status = _status;

- (instancetype)initWithPartition:(NSString *)partition
                     andDbAccount:(NSString *)dbAccount
                        andDbName:(NSString *)dbName
              andDbCollectionName:(NSString *)dbCollectionName
                         andToken:(NSString *)token
                        andStatus:(NSString *)status {
    self = [super init];
    if (self) {
        _partition = partition;
        _dbAccount = dbAccount;
        _dbName = dbName;
        _dbCollectionName = dbCollectionName;
        _token = token;
        _status = status;
    }
    return self;
}

@end
