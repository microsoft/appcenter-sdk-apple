#import "MSTokensResponse.h"
#import "MSDataStorageConstants.h"
#import "MSTokenResult.h"

@implementation MSTokensResponse

NSString *const kMSTokens = @"tokens";

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
        MSTokenResult *result = [[MSTokenResult alloc] initWithDictionary:dic];
        [tokenArray addObject:result];
      }
      _tokens = tokenArray;
    }
  }
  return self;
}
@end
