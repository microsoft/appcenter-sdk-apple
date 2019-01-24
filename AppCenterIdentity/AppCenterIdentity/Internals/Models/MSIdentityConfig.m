#import "MSIdentityConfig.h"

@implementation MSIdentityConfig

static NSString *const kMSIdentityScope = @"identity_scope";

static NSString *const kMSClientId = @"client_id";

static NSString *const kMSRedirectUri = @"redirect_uri";

static NSString *const kMSAuthorities = @"authorities";

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if ((self = [super init])) {
    if (dictionary[kMSIdentityScope]) {
      self.scope = (NSString * _Nonnull) dictionary[kMSIdentityScope];
    }
    if (dictionary[kMSClientId]) {
      self.clientId = (NSString * _Nonnull) dictionary[kMSClientId];
    }
    if (dictionary[kMSRedirectUri]) {
      self.redirectUri = (NSString * _Nonnull) dictionary[kMSRedirectUri];
    }
    if (dictionary[kMSAuthorities]) {
      NSMutableArray *array = [NSMutableArray new];
      for (NSDictionary *authorityDic in dictionary[kMSAuthorities]) {
        [array addObject:[[MSIdentityAuthority alloc] initWithDictionary:authorityDic]];
      }
      self.authorities = array;
    }
  }
  return self;
}

@end
