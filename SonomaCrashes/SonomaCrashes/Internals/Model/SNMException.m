/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMException.h"
#import "SNMStackFrame.h"

static NSString *const kSNMExceptionType = @"type";
static NSString *const kSNMReason = @"reason";
static NSString *const kSNMFrames = @"frames";
static NSString *const kSNMInnerExceptions = @"inner_exceptions";

@implementation SNMException

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.type) {
    dict[kSNMExceptionType] = self.type;
  }
  if (self.reason) {
    dict[kSNMReason] = self.reason;
  }
  if (self.frames) {
    NSMutableArray *framesArray = [NSMutableArray array];
    for (SNMStackFrame *frame in self.frames) {
      [framesArray addObject:[frame serializeToDictionary]];
    }
    dict[kSNMFrames] = framesArray;
  }
  if (self.innerExceptions) {
    NSMutableArray *exceptionsArray = [NSMutableArray array];
    for (SNMException *exception in self.innerExceptions) {
      [exceptionsArray addObject:[exception serializeToDictionary]];
    }
    dict[kSNMInnerExceptions] = exceptionsArray;    
  }

  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = [coder decodeObjectForKey:kSNMExceptionType];
    _reason = [coder decodeObjectForKey:kSNMReason];
    _frames = [coder decodeObjectForKey:kSNMFrames];
    _innerExceptions = [coder decodeObjectForKey:kSNMInnerExceptions];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.type forKey:kSNMExceptionType];
  [coder encodeObject:self.reason forKey:kSNMReason];
  [coder encodeObject:self.frames forKey:kSNMFrames];
  [coder encodeObject:self.innerExceptions forKey:kSNMInnerExceptions];
}

@end
