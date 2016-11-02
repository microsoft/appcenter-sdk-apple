/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMPageLog.h"

static NSString *const kSNMTypePage = @"page";

static NSString *const kSNMName = @"name";

@implementation SNMPageLog

@synthesize type = _type;

- (instancetype)init {
  if (self = [super init]) {
    _type = kSNMTypePage;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.name) {
    dict[kSNMName] = self.name;
  }
  return dict;
}

- (BOOL)isValid {
  if (!self.name)
    return NO;

  return [super isValid];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _type = [coder decodeObjectForKey:kMSType];
    _name = [coder decodeObjectForKey:kSNMName];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kMSType];
  [coder encodeObject:self.name forKey:kSNMName];
}

@end
