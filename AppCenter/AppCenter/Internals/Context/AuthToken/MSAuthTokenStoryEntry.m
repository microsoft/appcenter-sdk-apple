// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenStoryEntry.h"

@implementation MSAuthTokenStoryEntry

- (instancetype)initWithAuthToken:(nullable NSString *)authToken andTimestamp:(double)timestamp {
  self = [super init];
  if (self) {
    _authToken = authToken;
    _timestamp = timestamp;
  }
  return self;
}

- (instancetype)initWithAuthToken:(nullable NSString *)authToken {
  return [self initWithAuthToken:authToken andTimestamp:[[NSDate date] timeIntervalSince1970]];
}

- (NSDate *)timestampAsDate {
  return [NSDate dateWithTimeIntervalSince1970:self.timestamp];
}

@end