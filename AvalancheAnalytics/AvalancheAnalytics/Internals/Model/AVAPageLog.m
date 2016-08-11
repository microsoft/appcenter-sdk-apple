/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAPageLog.h"

static NSString *const kAVATypePage = @"page";

static NSString *const kAVAName = @"name";

@implementation AVAPageLog

@synthesize type = _type;

- (instancetype)init {
  if (self = [super init]) {
    _type = kAVATypePage;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.name) {
    dict[kAVAName] = self.name;
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
    _type = [coder decodeObjectForKey:kAVAType];
    _name = [coder decodeObjectForKey:kAVAName];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kAVAType];
  [coder encodeObject:self.name forKey:kAVAName];
}

@end
