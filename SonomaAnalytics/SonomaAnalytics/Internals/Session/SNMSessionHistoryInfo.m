/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMSessionHistoryInfo.h"

static NSString *const kSNMSessionIdKey = @"kSNMSessionIdKey";
static NSString *const kSNMToffsetKey = @"kSNMToffsetKey";

/**
 This class is used to associate session id with the timestamp that it was created.
 */

@implementation SNMSessionHistoryInfo

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _sessionId = [coder decodeObjectForKey:kSNMSessionIdKey];
    _toffset = [coder decodeObjectForKey:kSNMToffsetKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.sessionId forKey:kSNMSessionIdKey];
  [coder encodeObject:self.toffset forKey:kSNMToffsetKey];
}

@end
