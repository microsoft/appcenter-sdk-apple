#import "MSTokensResponse.h"
#import "MSTokenResult.h"

static NSString *const kMSTokens = @"tokens";
static NSString *const kMSDbName = @"dbName";
static NSString *const kMSStatus = @"status";
static NSString *const kMSPartition = @"partition";
static NSString *const kMSDbAccount = @"dbAccount";
static NSString *const kMSDbCollectionName = @"dbCollectionName";
static NSString *const kMSExpiresOn = @"expiresOn";
static NSString *const kMSToken = @"token";

@implementation MSTokensResponse

@synthesize tokens = _tokens;

- (instancetype)initWithTokens:(NSArray<MSTokenResult *> *)tokens {
  self = [super init];
  if (self) {
    _tokens = tokens;
  }
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)tokens {

  self = [super init];
  if (self) {
    NSInteger count = [(NSArray *)tokens[kMSTokens] count];
    if (count > 0) {
      NSMutableArray *tokenArray = [[NSMutableArray alloc] initWithCapacity:count];
      for (NSDictionary *dic in tokens[kMSTokens]) {
        MSTokenResult *result = [[MSTokenResult alloc] initWithPartition:dic[kMSPartition]
                                                               dbAccount:dic[kMSDbAccount]
                                                                  dbName:dic[kMSDbName]
                                                        dbCollectionName:dic[kMSDbCollectionName]
                                                                   token:dic[kMSToken]
                                                                  status:dic[kMSStatus]];
        [tokenArray addObject:result];
      }
      _tokens = tokenArray;
    }
  }
  return self;
}
@end
