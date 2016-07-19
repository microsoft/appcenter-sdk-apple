/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAException.h"

static NSString *const kAVAId = @"id";
static NSString *const kAVAReason = @"reason";
static NSString *const kAVALanguage = @"language";
static NSString *const kAVAFrames = @"frames";
static NSString *const kAVAInnerExceptions = @"innerExceptions";

@implementation AVAException

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  
  if (self.exceptionId) {
    dict[kAVAId] = self.exceptionId;
  }
  if (self.reason) {
    dict[kAVAReason] = self.reason;
  }
  if (self.language) {
    dict[kAVALanguage] = self.language;
  }
  if (self.frames) {
    dict[kAVAFrames] = self.frames;
  }
  if (self.innerExceptions) {
    dict[kAVAInnerExceptions] = self.innerExceptions;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if(self) {
    _exceptionId = [coder decodeObjectForKey:kAVAId];
    _reason = [coder decodeObjectForKey:kAVAReason];
    _language = [coder decodeObjectForKey:kAVALanguage];
    _frames = [coder decodeObjectForKey:kAVAFrames];
    _innerExceptions = [coder decodeObjectForKey:kAVAInnerExceptions];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.exceptionId forKey:kAVAId];
  [coder encodeObject:self.reason forKey:kAVAReason];
  [coder encodeObject:self.language forKey:kAVALanguage];
  [coder encodeObject:self.frames forKey:kAVAFrames];
  [coder encodeObject:self.innerExceptions forKey:kAVAInnerExceptions];
}

@end
