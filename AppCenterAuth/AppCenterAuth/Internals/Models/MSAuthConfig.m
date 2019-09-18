// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAADAuthority.h"
#import "MSAuthConfig.h"
#import "MSAuthConstants.h"
#import "MSB2CAuthority.h"

@implementation MSAuthConfig

static NSString *const kMSAuthScopeKey = @"identity_scope";

static NSString *const kMSClientIdKey = @"client_id";

static NSString *const kMSRedirectUriKey = @"redirect_uri";

static NSString *const kMSAuthoritiesKey = @"authorities";

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if ((self = [super init])) {
    if (dictionary[kMSAuthScopeKey]) {
      self.authScope = (NSString * _Nonnull) dictionary[kMSAuthScopeKey];
    }
    if (dictionary[kMSClientIdKey]) {
      self.clientId = (NSString * _Nonnull) dictionary[kMSClientIdKey];
    }
    if (dictionary[kMSRedirectUriKey]) {
      self.redirectUri = (NSString * _Nonnull) dictionary[kMSRedirectUriKey];
    }
    if (dictionary[kMSAuthoritiesKey]) {
      NSMutableArray *array = [NSMutableArray new];
      for (NSDictionary *authorityDic in dictionary[kMSAuthoritiesKey]) {
        MSAuthority *authority = nil;
        if (!authorityDic || !authorityDic[kMSTypeKey]) {
          [array addObject:authority];
          continue;
        }
        NSString *authorityType = (NSString * _Nonnull) authorityDic[kMSTypeKey];
        
        if ([authorityType isEqualToString:kMSAuthorityTypeB2C]) {
          authority = [[MSB2CAuthority alloc] initWithDictionary:authorityDic];
        } else if ([authorityType isEqualToString:kMSAuthorityTypeAAD]) {
          authority = [[MSAADAuthority alloc] initWithDictionary:authorityDic];
        }
        
        /* Return default authority which is neither B2C nor AAD. */
        authority = [[MSAuthority alloc] initWithDictionary:authorityDic];
        [array addObject:authority];
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
    if (![authority isValid]) {
      return NO;
    }
    if (authority.defaultAuthority && [authority isValidType]) {
      foundDefault = YES;
    }
  }
  return foundDefault;
}

@end
