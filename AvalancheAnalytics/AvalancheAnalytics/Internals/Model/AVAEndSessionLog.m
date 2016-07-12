/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAEndSessionLog.h"

static NSString *const kAVATypeEndSession = @"endSession";

@implementation AVAEndSessionLog

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

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
  
  NSArray *optionalProperties = @[];
  return [optionalProperties containsObject:propertyName];
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
