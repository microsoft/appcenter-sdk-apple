/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAThread.h"
#import "AVAException.h"
#import "AVAStackFrame.h"

static NSString *const kAVAThreadId = @"id";
static NSString *const kAVAName = @"name";
static NSString *const kAVAStackFrames = @"stackFrames";
static NSString *const kAVAException = @"exception";


@implementation AVAThread

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.threadId) {
    dict[kAVAThreadId] = self.threadId;
  }
  if(self.name) {
    dict[kAVAName] = self.name;
  }
  
  if (self.frames) {
    NSMutableArray *framesArray = [NSMutableArray array];
    for (AVAStackFrame *frame in self.frames) {
      [framesArray addObject:[frame serializeToDictionary]];
    }
    dict[kAVAStackFrames] = framesArray;
  }
  
  if(self.exception) {
    dict[kAVAException] = self.exception;
  }
 
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _threadId = [coder decodeObjectForKey:kAVAThreadId];
    _name = [coder decodeObjectForKey:kAVAName];
    _frames = [coder decodeObjectForKey:kAVAStackFrames];
    _exception = [coder decodeObjectForKey:kAVAException];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.threadId forKey:kAVAThreadId];
  [coder encodeObject:self.name forKey:kAVAName];
  [coder encodeObject:self.frames forKey:kAVAStackFrames];
  [coder encodeObject:self.exception forKey:kAVAException];
}

@end
