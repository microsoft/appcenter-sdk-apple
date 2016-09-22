/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMThread.h"
#import "SNMException.h"
#import "SNMStackFrame.h"

static NSString *const kSNMThreadId = @"id";
static NSString *const kSNMName = @"name";
static NSString *const kSNMStackFrames = @"frames";
static NSString *const kSNMException = @"exception";


@implementation SNMThread


// Initializes a new instance of the class.
- (instancetype)init {
  if (self = [super init]) {
    _frames = [NSMutableArray array];
  }
  return self;
}


- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.threadId) {
    dict[kSNMThreadId] = self.threadId;
  }
  if (self.name) {
    dict[kSNMName] = self.name;
  }
  
  if (self.frames) {
    NSMutableArray *framesArray = [NSMutableArray array];
    for (SNMStackFrame *frame in self.frames) {
      [framesArray addObject:[frame serializeToDictionary]];
    }
    dict[kSNMStackFrames] = framesArray;
  }
  
  if (self.exception) {
    dict[kSNMException] = [self.exception serializeToDictionary];
  }
 
  return dict;
}

- (BOOL)isValid {
  return self.threadId && self.frames;
}

- (BOOL)isEqual:(SNMThread *)thread {
  if (!thread)
    return NO;
  
  return ((!self.threadId && !thread.threadId) || [self.threadId isEqual:thread.threadId]) &&
         ((!self.name && !thread.name) || [self.name isEqualToString:thread.name]) &&
         ((!self.frames && !thread.frames) || [self.frames isEqualToArray:thread.frames]) &&
         ((!self.exception && !thread.exception) || [self.exception isEqual:thread.exception]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _threadId = [coder decodeObjectForKey:kSNMThreadId];
    _name = [coder decodeObjectForKey:kSNMName];
    _frames = [coder decodeObjectForKey:kSNMStackFrames];
    _exception = [coder decodeObjectForKey:kSNMException];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.threadId forKey:kSNMThreadId];
  [coder encodeObject:self.name forKey:kSNMName];
  [coder encodeObject:self.frames forKey:kSNMStackFrames];
  [coder encodeObject:self.exception forKey:kSNMException];
}

@end
