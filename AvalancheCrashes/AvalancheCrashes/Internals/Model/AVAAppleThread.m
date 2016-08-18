/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAppleThread.h"
#import "AVAAppleException.h"

static NSString *const kAVAId = @"id";
static NSString *const kAVAName = @"name";
static NSString *const kAVALastException = @"lastException";
static NSString *const kAVAFrames = @"frames";

@implementation AVAAppleThread

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.threadId) {
    dict[kAVAId] = self.threadId;
  }
  if(self.name) {
    dict[kAVAName] = self.name;
  }
  if(self.lastException) {
    dict[kAVAName] = self.lastException;
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
    _threadId = [coder decodeObjectForKey:kAVAId];
    _name = [coder decodeObjectForKey:kAVAName];
    _lastException = [coder decodeObjectForKey:kAVALastException];
    _frames = [coder decodeObjectForKey:kAVAFrames];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.threadId forKey:kAVAId];
  [coder encodeObject:self.name forKey:kAVAName];
  [coder encodeObject:self.lastException forKey:kAVALastException];
  [coder encodeObject:self.frames forKey:kAVAFrames];
}

@end
