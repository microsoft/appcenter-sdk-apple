/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVALogUtils.h"
#import "AVALogWithProperties.h"
#import "AVALogger.h"

static NSString *const kAVAProperties = @"properties";

@implementation AVALogWithProperties

@synthesize properties;

- (void)write:(NSMutableDictionary *)dic {
  [super write:dic];

  // Set properties
  if (self.properties)
    dic[kAVAProperties] = self.properties;
}

- (void)read:(NSDictionary *)obj {
  [super read:obj];

  self.properties = obj[kAVAProperties];
}

- (BOOL)isValid {
  BOOL isValid = YES;

  isValid = (!self.properties || [super isValid]);
  return isValid;
}

@end