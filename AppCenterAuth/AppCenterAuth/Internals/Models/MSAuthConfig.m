// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthConfig.h"

@implementation MSAuthConfig

static NSString *const kMSAuthScope = @"identity_scope";

static NSString *const kMSClientId = @"client_id";

static NSString *const kMSRedirectUri = @"redirect_uri";

static NSString *const kMSAuthorities = @"authorities";

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if ((self = [super init])) {
    if (dictionary[kMSAuthScope]) {
      self.authScope = (NSString * _Nonnull)dictionary[kMSAuthScope];
    }
    if (dictionary[kMSClientId]) {
      self.clientId = (NSString * _Nonnull)dictionary[kMSClientId];
    }
    if (dictionary[kMSRedirectUri]) {
      self.redirectUri = (NSString * _Nonnull)dictionary[kMSRedirectUri];
    }
    if (dictionary[kMSAuthorities]) {
      NSMutableArray *array = [NSMutableArray new];
      for (NSDictionary *authorityDic in dictionary[kMSAuthorities]) {
        [array addObject:[MSAuthority authorityWithDictionary:authorityDic]];
      }
      self.authorities = array;
    }
  }
  return self;
}

- (BOOL)isValid {
  return self.authScope && self.clientId && self.redirectUri && [self areAuthoritiesValid];
}

- (BOOL)areAuthoritiesValid {
  BOOL foundDefault = NO;
  for (MSAuthority *authority in self.authorities) {
    if ([authority isValid]) {
      return NO;
    }
    if (authority.defaultAuthority) {
      foundDefault = YES;
    }
  }
  return foundDefault;
}

@end
