/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAppleException.h"

static NSString *const kAVAExceptionType = @"type";
static NSString *const kAVAReason = @"reason";
static NSString *const kAVAFrames = @"frames";

@implementation AVAAppleException

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.type) {
    dict[kAVAExceptionType] = self.type;
  }
  if (self.reason) {
    dict[kAVAReason] = self.reason;
  }
  if (self.frames) {
    dict[kAVAFrames] = self.frames;
  }

  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = [coder decodeObjectForKey:kAVAType];
    _reason = [coder decodeObjectForKey:kAVAReason];
    _frames = [coder decodeObjectForKey:kAVAFrames];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.type forKey:kAVAType];
  [coder encodeObject:self.reason forKey:kAVAReason];
  [coder encodeObject:self.frames forKey:kAVAFrames];
}

@end
