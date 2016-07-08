/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAEventLog.h"

static NSString *const kAVATypeEvent = @"Event";

@implementation AVAEventLog

- (instancetype)init {
  if (self = [super init]) {
    self.type = kAVATypeEvent;
  }
  return self;
}

- (void)write:(NSMutableDictionary *)dic {
  [super write:dic];
}

- (void)read:(NSDictionary *)obj {
  [super read:obj];
}

- (BOOL)isValid {
  return [super isValid];
}

@end
