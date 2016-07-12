/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAPageLog.h"

static NSString *const kAVATypePage = @"page";

@implementation AVAPageLog

- (instancetype)init {
  if (self = [super init]) {
    self.type = kAVATypePage;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  return dict;
}

- (BOOL)isValid {
  return [super isValid];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if(self) {
  }
  
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
}

@end
