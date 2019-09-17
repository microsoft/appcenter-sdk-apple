// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthority.h"
#import "MSB2CAuthority.h"
#import "MSAADAuthority.h"
#import "../Util/MSAuthConstants.h"

@implementation MSAuthority

static NSString *const kMSType = @"type";

static NSString *const kMSDefault = @"default";

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if ((self = [super init])) {
    if (dictionary[kMSType]) {
      self.type = (NSString * _Nonnull)dictionary[kMSType];
    }
    if (dictionary[kMSDefault]) {
      self.defaultAuthority = [(NSNumber *)dictionary[kMSDefault] boolValue];
    }
  }
  return self;
}

- (BOOL)isValid {
  return self.type && self.authorityUrl;
}

+ (MSAuthority *)authorityWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary || !dictionary[kMSType]) {
    return nil;
  }
  NSString *authorityType = (NSString * _Nonnull)dictionary[kMSType];

  if ([authorityType isEqualToString:kMSAuthorityTypeB2C]) {
    return [[MSB2CAuthority alloc] initWithDictionary:dictionary];
  } else if ([authorityType isEqualToString:kMSAuthorityTypeAAD]) {
    return [[MSAADAuthority alloc] initWithDictionary:dictionary];
  }
  return nil;
}

@end
