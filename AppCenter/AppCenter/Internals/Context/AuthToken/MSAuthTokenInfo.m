// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenInfo.h"

@implementation MSAuthTokenInfo

- (instancetype)initWithAuthToken:(nullable NSString *)authToken
                     andStartTime:(nullable NSDate *)startTime
                       andEndTime:(nullable NSDate *)endTime {
  self = [super init];
  if (self) {
    _authToken = authToken;
    _startTime = startTime;
    _endTime = endTime;
  }
  return self;
}

@end
