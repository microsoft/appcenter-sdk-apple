// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#include "MSUserInformation.h"

@implementation MSUserInformation

- (instancetype)initWithAccountId:(nonnull NSString *)accountId {
  self = [super init];
  if (self) {
    _accountId = accountId;
  }
  return self;
}
@end
