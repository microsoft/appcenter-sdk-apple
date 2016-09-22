/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMException.h"
#import "SNMStackFrame.h"

static NSString *const kSNMExceptionType = @"type";
static NSString *const kSNMMessage = @"message";
static NSString *const kSNMFrames = @"frames";
static NSString *const kSNMInnerExceptions = @"inner_exceptions";

@implementation SNMException

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.type) {
    dict[kSNMExceptionType] = self.type;
  }
  if (self.message) {
    dict[kSNMMessage] = self.message;
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

- (BOOL)isValid {
  return self.type && self.frames;
}

- (BOOL)isEqual:(SNMException *)exception {
  if (!exception)
    return NO;
  
  return ((!self.type && !exception.type) || [self.type isEqualToString:exception.type]) &&
         ((!self.message && !exception.message) || [self.type isEqualToString:exception.message]) &&
         ((!self.frames && !exception.frames) || [self.frames isEqualToArray:exception.frames]) &&
         ((!self.innerExceptions && !exception.innerExceptions) || [self.innerExceptions isEqual:exception.innerExceptions]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = [coder decodeObjectForKey:kSNMExceptionType];
    _message = [coder decodeObjectForKey:kSNMMessage];
    _frames = [coder decodeObjectForKey:kSNMFrames];
    _innerExceptions = [coder decodeObjectForKey:kSNMInnerExceptions];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.type forKey:kSNMExceptionType];
  [coder encodeObject:self.message forKey:kSNMMessage];
  [coder encodeObject:self.frames forKey:kSNMFrames];
  [coder encodeObject:self.innerExceptions forKey:kSNMInnerExceptions];
}

@end
