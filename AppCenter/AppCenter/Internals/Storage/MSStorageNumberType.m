// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSStorageNumberType.h"
#import <sqlite3.h>

@implementation MSStorageNumberType

- (instancetype)initWithValue:(NSNumber *)value {
  if ((self = [super init])) {
    _value = value;
  }
  return self;
}

- (int)bindWithStatement:(void *)query atIndex:(int)index {
  return sqlite3_bind_int64(query, index, [self.value longLongValue]);
}

@end
