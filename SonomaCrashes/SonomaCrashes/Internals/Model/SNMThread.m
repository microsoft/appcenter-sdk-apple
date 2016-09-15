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

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.threadId) {
    dict[kSNMThreadId] = self.threadId;
  }
  if(self.name) {
    dict[kSNMName] = self.name;
  }
  
  if (self.frames) {
    NSMutableArray *framesArray = [NSMutableArray array];
    for (SNMStackFrame *frame in self.frames) {
      [framesArray addObject:[frame serializeToDictionary]];
    }
    dict[kSNMStackFrames] = framesArray;
  }
  
  if(self.exception) {
    dict[kSNMException] = self.exception;
  }
 
  return dict;
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
