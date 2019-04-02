// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#include "MSUserInformation.h"

@implementation MSUserInformation

- (instancetype)initWithAccountId:(nullable NSString *)accountId {
  self = [super init];
  if (self) {
    _accountId = accountId;
  }
  return self;
}

- (BOOL)isEqualTo:(nullable id)userInfo {
  MSUserInformation *user = (MSUserInformation *)userInfo;
  return [self.accountId isEqualToString:user.accountId ?: nil];
}
@end
