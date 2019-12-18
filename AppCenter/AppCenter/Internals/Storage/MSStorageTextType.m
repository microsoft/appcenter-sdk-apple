// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSStorageTextType.h"
#import <sqlite3.h>

@implementation MSStorageTextType

- (instancetype)initWithValue:(NSString *)value {
  if ((self = [super init])) {
    _value = value;
  }
  return self;
}

- (int)bindWithStatement:(sqlite3_stmt *)query atIndex:(int)index {
  return sqlite3_bind_text(query, index, [self.value UTF8String], -1, SQLITE_TRANSIENT);
}

@end
