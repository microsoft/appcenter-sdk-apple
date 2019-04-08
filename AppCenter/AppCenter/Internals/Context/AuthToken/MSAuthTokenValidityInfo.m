// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenValidityInfo.h"

/**
 * If the given number of seconds is left until the token expires, it indicates that it needs refreshing.
 */
static NSTimeInterval const kMSSecBeforeExpireToRefresh = 10 * 60;

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

- (BOOL)expiresSoon {
  NSDate *endTimeThreadSafe;
  endTimeThreadSafe = self.endTime;
  NSDate *futureDate = [NSDate dateWithTimeIntervalSinceNow:kMSSecBeforeExpireToRefresh];
  return endTimeThreadSafe && [futureDate compare:(NSDate * __nonnull) endTimeThreadSafe] == NSOrderedDescending;
}

@end
