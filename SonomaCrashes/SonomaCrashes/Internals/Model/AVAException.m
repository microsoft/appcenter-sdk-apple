/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAException.h"
#import "AVAStackFrame.h"

static NSString *const kAVAExceptionType = @"type";
static NSString *const kAVAReason = @"reason";
static NSString *const kAVAFrames = @"frames";
static NSString *const kAVAInnerExceptions = @"innerExceptions";

@implementation AVAException

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.type) {
    dict[kAVAExceptionType] = self.type;
  }
  if (self.reason) {
    dict[kAVAReason] = self.reason;
  }
  if (self.frames) {
    NSMutableArray *framesArray = [NSMutableArray array];
    for (AVAStackFrame *frame in self.frames) {
      [framesArray addObject:[frame serializeToDictionary]];
    }
    dict[kAVAFrames] = framesArray;
  }
  if (self.innerExceptions) {
    NSMutableArray *exceptionsArray = [NSMutableArray array];
    for (AVAException *exception in self.innerExceptions) {
      [exceptionsArray addObject:[exception serializeToDictionary]];
    }
    dict[kAVAInnerExceptions] = exceptionsArray;    
  }

  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = [coder decodeObjectForKey:kAVAExceptionType];
    _reason = [coder decodeObjectForKey:kAVAReason];
    _frames = [coder decodeObjectForKey:kAVAFrames];
    _innerExceptions = [coder decodeObjectForKey:kAVAInnerExceptions];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.type forKey:kAVAExceptionType];
  [coder encodeObject:self.reason forKey:kAVAReason];
  [coder encodeObject:self.frames forKey:kAVAFrames];
  [coder encodeObject:self.innerExceptions forKey:kAVAInnerExceptions];
}

@end
