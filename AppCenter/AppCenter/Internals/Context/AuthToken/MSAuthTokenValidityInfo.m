// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenValidityInfo.h"

@implementation MSAuthTokenValidityInfo

- (instancetype)initWithAuthToken:(nullable NSString *)authToken startTime:(nullable NSDate *)startTime endTime:(nullable NSDate *)endTime {
  self = [super init];
  if (self) {
    _authToken = authToken;
    _startTime = startTime;
    _endTime = endTime;
  }
  return self;
}

@end
