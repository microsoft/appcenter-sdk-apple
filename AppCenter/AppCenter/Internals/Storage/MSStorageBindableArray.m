// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "MSStorageBindableArray.h"
#import "MSAppCenterInternal.h"
#import "MSStorageNumberType.h"
#import "MSStorageTextType.h"

@implementation MSStorageBindableArray

- (instancetype)init {
  if ((self = [super init])) {
    _array = [NSMutableArray new];
  }
  return self;
}

- (void)addString:(nullable NSString *)value {
  [self.array addObject:[[MSStorageTextType alloc] initWithValue:value]];
}

- (void)addNumber:(nonnull NSNumber *)value {
  [self.array addObject:[[MSStorageNumberType alloc] initWithValue:value]];
}

- (int)bindAllValuesWithStatement:(void *)query inOpenedDatabase:(void *)db {
  for (int i = 0; i < (int)self.array.count; i++) {
    id<MSStorageBindableType> value = self.array[i];
    int result = [value bindWithStatement:query atIndex:i + 1];
    if (result != SQLITE_OK) {
      MSLogError([MSAppCenter logTag], @"Binding query parameter %d failed with error: %d. Message: %@", i + 1, result,
                 [NSString stringWithUTF8String:sqlite3_errmsg(db)]);
      return result;
    }
  }
  return SQLITE_OK;
}

@end
