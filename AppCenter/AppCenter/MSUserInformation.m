// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#include "MSUserInformation.h"

@implementation MSUserInformation

- (instancetype)initWithAccountId:(nonnull NSString *)accountId {
  if ((self = [super init])) {
    _accountId = accountId;
  }
  return self;
}
@end
