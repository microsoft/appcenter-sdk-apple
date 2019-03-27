// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenInfo.h"
#import "MSAuthTokenHistoryState.h"

static NSString *const kMSAuthTokenKey = @"authTokenKey";
static NSString *const kMSAccountIdKey = @"accountIdKey";
static NSString *const kMSStartTimeKey = @"startTimeKey";
static NSString *const kMSEndTimeKey = @"endTimeKey";

@implementation MSAuthTokenInfo

- (instancetype)initWithAuthToken:(nullable NSString *)authToken
                     andAccountId:(nullable NSString *)accountId
                     andStartTime:(nullable NSDate *)startTime
                       andEndTime:(nullable NSDate *)endTime {
  self = [super init];
  if (self) {
    _authToken = authToken;
    _accountId = accountId;
    _startTime = startTime;
    _endTime = endTime;
  }
  return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _authToken = [coder decodeObjectForKey:kMSAuthTokenKey];
    _accountId = [coder decodeObjectForKey:kMSAccountIdKey];
    _startTime = [coder decodeObjectForKey:kMSStartTimeKey];
    _endTime = [coder decodeObjectForKey:kMSEndTimeKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.authToken forKey:kMSAuthTokenKey];
  [coder encodeObject:self.accountId forKey:kMSAccountIdKey];
  [coder encodeObject:self.startTime forKey:kMSStartTimeKey];
  [coder encodeObject:self.endTime forKey:kMSEndTimeKey];
}

@end
