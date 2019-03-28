// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenValidityInfo.h"

// If the given number of seconds is left until the token expires, it indicates that it needs refreshing.
static int const kMSSecBeforeExpireToRefresh = 10 * 60;

@implementation MSAuthTokenValidityInfo

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

- (BOOL)expiresSoon {
  NSDate *currentDate = [NSDate date];
  NSTimeInterval seconds = kMSSecBeforeExpireToRefresh;
  return [[NSDate dateWithTimeIntervalSinceNow:seconds] laterDate:currentDate];
}

@end
