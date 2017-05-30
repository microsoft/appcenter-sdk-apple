/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "EventLog.h"

@implementation EventLog

- (instancetype)init {
  self = [super init];
  if (self) {
    self.eventName = @"";
    self.properties = [NSMutableDictionary new];
  }
  return self;
}

@end
