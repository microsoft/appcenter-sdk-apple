#import "MSTokensResponse.h"

@implementation MSTokensResponse

@synthesize tokens = _tokens;

-(instancetype) initWithTokens:(NSArray<MSTokenResult *> *)tokens {
    self = [super init];
    if (self) {
        _tokens = tokens;
    }
    return self;
}

@end

