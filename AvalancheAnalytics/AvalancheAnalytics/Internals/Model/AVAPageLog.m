/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAPageLog.h"

static NSString *const kAVATypePage = @"Page";

@implementation AVAPageLog

- (instancetype)init {
  if (self = [super init]) {
    self.type = kAVATypePage;
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
