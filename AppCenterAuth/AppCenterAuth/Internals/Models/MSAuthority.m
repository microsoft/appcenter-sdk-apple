// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthority.h"
#import "MSAADAuthority.h"
#import "MSAuthConstants.h"
#import "MSB2CAuthority.h"

@implementation MSAuthority

static NSString *const kMSTypeKey = @"type";

static NSString *const kMSDefaultKey = @"default";

static NSString *const kMSAuthorityUrlKey = @"authority_url";

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if ((self = [super init])) {
    if (dictionary[kMSTypeKey]) {
      self.type = (NSString * _Nonnull) dictionary[kMSTypeKey];
    }
    if (dictionary[kMSDefaultKey]) {
      self.defaultAuthority = [(NSNumber *)dictionary[kMSDefaultKey] boolValue];
    }
    if (dictionary[kMSAuthorityUrlKey]) {
      if (![(NSObject *)dictionary[kMSAuthorityUrlKey] isKindOfClass:[NSNull class]]) {
        NSString *_Nonnull authorityUrl = (NSString * _Nonnull) dictionary[kMSAuthorityUrlKey];
        self.authorityUrl = (NSURL * _Nonnull)[NSURL URLWithString:authorityUrl];
      }
    }
  }
  return self;
}

- (BOOL)isValid {
  return self.type && self.authorityUrl;
}

- (BOOL)isValidType {
  return NO;
}

+ (MSAuthority *)authorityWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary || !dictionary[kMSTypeKey]) {
    return nil;
  }
  NSString *authorityType = (NSString * _Nonnull) dictionary[kMSTypeKey];

  if ([authorityType isEqualToString:kMSAuthorityTypeB2C]) {
    return [[MSB2CAuthority alloc] initWithDictionary:dictionary];
  } else if ([authorityType isEqualToString:kMSAuthorityTypeAAD]) {
    return [[MSAADAuthority alloc] initWithDictionary:dictionary];
  }

  /* Return default authority which is neither B2C nor AAD. */
  return [[MSAuthority alloc] initWithDictionary:dictionary];
}

@end
