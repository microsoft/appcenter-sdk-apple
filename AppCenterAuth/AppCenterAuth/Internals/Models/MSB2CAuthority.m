// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSB2CAuthority.h"
#import "MSAuthConstants.h"

@implementation MSB2CAuthority

- (BOOL)isValidType {
  return [self.type isEqualToString:kMSAuthorityTypeB2C];
}

@end
