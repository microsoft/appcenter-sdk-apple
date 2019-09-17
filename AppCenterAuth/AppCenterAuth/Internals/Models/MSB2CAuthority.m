// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSB2CAuthority.h"
#import "../Util/MSAuthConstants.h"

@implementation MSB2CAuthority

static NSString *const kMSType = @"type";

static NSString *const kMSDefault = @"default";

static NSString *const kMSAuthorityUrl = @"authority_url";

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if((self = [super initWithDictionary:dictionary])){
    if (dictionary[kMSAuthorityUrl]) {
      if (![(NSObject *)dictionary[kMSAuthorityUrl] isKindOfClass:[NSNull class]]) {
        NSString *_Nonnull authorityUrl = (NSString * _Nonnull)dictionary[kMSAuthorityUrl];
        self.authorityUrl = (NSURL * _Nonnull)[NSURL URLWithString:authorityUrl];
      }
    }
  }
  if (![self isValid]) {
    return nil;
  }
  return self;
}

- (BOOL)isValid {
  return [super isValid] && [self.type isEqualToString:kMSAuthorityTypeB2C];
}

@end

