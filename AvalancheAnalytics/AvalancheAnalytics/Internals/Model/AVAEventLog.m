/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAEventLog.h"

static NSString *const kAVATypeEvent = @"event";

static NSString *const kAVAId = @"id";
static NSString *const kAVAName = @"name";

@implementation AVAEventLog

@synthesize type = _type;

- (instancetype)init {
  if (self = [super init]) {
     _type= kAVATypeEvent;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  
  if (self.eventId) {
    dict[kAVAId] = self.eventId;
  }
  if (self.name) {
    dict[kAVAName] = self.name;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if(self) {
    _type = [coder decodeObjectForKey:kAVAType];
    _eventId = [coder decodeObjectForKey:kAVAId];
    _name = [coder decodeObjectForKey:kAVAName];
  }
  
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kAVAType];
  [coder encodeObject:self.eventId forKey:kAVAId];
  [coder encodeObject:self.name forKey:kAVAName];
}

@end
