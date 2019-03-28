// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenValidityInfo.h"

@implementation MSAuthTokenValidityInfo

- (instancetype)initWithAuthToken:(nullable NSString *)authToken
                     andStartTime:(nullable NSDate *)startTime
                     andExpiresOn:(nullable NSDate *)expiresOn {
  self = [super init];
  if (self) {
    _authToken = authToken;
    _startTime = startTime;
    _expiresOn = expiresOn;
  }
  return self;
}

@end
