/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSLogWithProperties.h"

static NSString *const kMSProperties = @"properties";

@implementation MSLogWithProperties

@synthesize properties = _properties;

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.properties) {
    dict[kMSProperties] = self.properties;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _properties = [coder decodeObjectForKey:kMSProperties];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.properties forKey:kMSProperties];
}

@end
