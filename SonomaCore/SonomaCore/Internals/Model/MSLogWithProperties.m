/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSLogUtils.h"
#import "MSLogWithProperties.h"
#import "MSLogger.h"
#import "MSLogContainer.h"

static NSString *const kSNMProperties = @"properties";

@implementation MSLogWithProperties

@synthesize properties = _properties;

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.properties) {
    dict[kSNMProperties] = self.properties;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _properties = [coder decodeObjectForKey:kSNMProperties];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.properties forKey:kSNMProperties];
}

@end
