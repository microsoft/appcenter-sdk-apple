/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAEndSessionLog.h"

static NSString *const kAVATypeEndSession = @"endSession";

@implementation AVAEndSessionLog

- (instancetype)init {
  if (self = [super init]) {
    self.type = kAVATypeEndSession;
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
