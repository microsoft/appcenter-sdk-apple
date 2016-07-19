/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAStartSessionLog.h"

static NSString *const kAVATypeEndSession = @"startSession";

@implementation AVAStartSessionLog

@synthesize type = _type;

- (instancetype)init {
  if (self = [super init]) {
    _type = kAVATypeEndSession;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  return dict;
}

- (BOOL)isValid {
  return [super isValid];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if(self) {
    _type = [coder decodeObjectForKey:kAVAType];
  }
  
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kAVAType];
}

@end
