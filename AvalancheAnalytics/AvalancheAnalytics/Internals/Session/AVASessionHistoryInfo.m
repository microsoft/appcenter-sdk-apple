/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASessionHistoryInfo.h"

static NSString *const kAVASessionIdKey = @"kAVASessionIdKey";
static NSString *const kAVAToffsetKey = @"kAVAToffsetKey";

@implementation AVASessionHistoryInfo

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _sessionId = [coder decodeObjectForKey:kAVASessionIdKey];
    _toffset = [coder decodeObjectForKey:kAVAToffsetKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.sessionId forKey:kAVASessionIdKey];
  [coder encodeObject:self.toffset forKey:kAVAToffsetKey];
}

@end
