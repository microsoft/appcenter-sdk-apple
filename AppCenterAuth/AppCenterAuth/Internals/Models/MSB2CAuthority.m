// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSB2CAuthority.h"

@implementation MSB2CAuthority

static NSString *const kMSAuthorityTypeB2C = @"B2C";

- (BOOL)isValidType {
  return [self.type isEqualToString:kMSAuthorityTypeB2C];
}

@end
