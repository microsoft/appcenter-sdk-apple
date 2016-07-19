/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVALogUtils.h"
#import "AVALogWithProperties.h"
#import "AVALogger.h"

static NSString *const kAVAProperties = @"properties";

@implementation AVALogWithProperties

@synthesize properties = _properties;

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  
  if (self.properties) {
    dict[kAVAProperties] = self.properties;
  }
  return dict;
}

- (BOOL)isValid {
  BOOL isValid = YES;

  isValid = (!self.properties || [super isValid]);
  return isValid;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if(self) {
    _properties = [coder decodeObjectForKey:kAVAProperties];
  }
  
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.properties forKey:kAVAProperties];
}

@end