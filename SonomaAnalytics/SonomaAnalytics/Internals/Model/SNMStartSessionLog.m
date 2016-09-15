/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMStartSessionLog.h"

static NSString *const kSNMTypeEndSession = @"start_session";

@implementation SNMStartSessionLog

@synthesize type = _type;

- (instancetype)init {
  if (self = [super init]) {
    _type = kSNMTypeEndSession;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _type = [coder decodeObjectForKey:kSNMType];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kSNMType];
}

@end
