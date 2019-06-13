// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#include "MSUserInformation.h"

@implementation MSUserInformation

- (instancetype)initWithAccountId:(NSString *)accountId accessToken:(NSString *)accessToken idToken:(NSString *)idToken {
  if ((self = [super init])) {
    _accountId = accountId;
    _accessToken = accessToken;
    _idToken = idToken;
  }
  return self;
}
@end
