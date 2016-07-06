/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAEndSessionLog.h"

static NSString* const kAVATypeEndSession = @"EndSession";

@implementation AVAEndSessionLog

- (instancetype)init {
  self = [super init];
  if (self) {
    self.type = kAVATypeEndSession;
  }
  return self;
}

/**
 * Indicates whether the property with the given name is optional.
 * If `propertyName` is optional, then return `YES`, otherwise return `NO`.
 * This method is used by `JSONModel`.
 */
+ (BOOL)propertyIsOptional:(NSString *)propertyName {

  NSArray *optionalProperties = @[@"properties", ];
  return [optionalProperties containsObject:propertyName];
}

- (void)write:(NSMutableDictionary*)dic {
  [super write:dic];
}

- (void)read:(NSDictionary*)obj{
  [super read:obj];
}

- (BOOL)isValid {
  return [super isValid];
}

@end
