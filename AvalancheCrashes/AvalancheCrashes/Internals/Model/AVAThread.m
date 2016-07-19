/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAThread.h"

static NSString *const kAVAId = @"id";
static NSString *const kAVAFrames = @"frames";

@implementation AVAThread

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  
  if (self.threadId) {
    dict[kAVAId] = self.threadId;
  }
  if (self.frames) {
    dict[kAVAFrames] = self.frames;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if(self) {
    _threadId = [coder decodeObjectForKey:kAVAId];
    _frames = [coder decodeObjectForKey:kAVAFrames];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.threadId forKey:kAVAId];
  [coder encodeObject:self.frames forKey:kAVAFrames];
}

@end
