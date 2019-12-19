// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSStorageNullType.h"
#import <sqlite3.h>

@implementation MSStorageNullType

- (int)bindWithStatement:(void *)query atIndex:(int)index {
  return sqlite3_bind_null(query, index);
}

@end
