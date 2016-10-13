/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMLogUtils.h"
#import "SNMLogWithProperties.h"
#import "SNMLogger.h"
#import "SNMLogContainer.h"

static NSString *const kSNMProperties = @"properties";

@implementation SNMLogWithProperties

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
