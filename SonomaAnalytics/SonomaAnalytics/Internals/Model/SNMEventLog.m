/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMEventLog.h"

static NSString *const kSNMTypeEvent = @"event";

static NSString *const kSNMId = @"id";
static NSString *const kSNMName = @"name";

@implementation SNMEventLog

@synthesize type = _type;

- (instancetype)init {
  if (self = [super init]) {
    _type = kSNMTypeEvent;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.eventId) {
    dict[kSNMId] = self.eventId;
  }
  if (self.name) {
    dict[kSNMName] = self.name;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _type = [coder decodeObjectForKey:kSNMType];
    _eventId = [coder decodeObjectForKey:kSNMId];
    _name = [coder decodeObjectForKey:kSNMName];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kSNMType];
  [coder encodeObject:self.eventId forKey:kSNMId];
  [coder encodeObject:self.name forKey:kSNMName];
}

@end
