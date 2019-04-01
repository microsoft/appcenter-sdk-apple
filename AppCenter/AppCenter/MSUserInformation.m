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

- (BOOL)compareUser:(MSUserInformation *)userInfor {
  return [self.accountId isEqualToString:userInfor.accountId ?: nil];
}
@end
