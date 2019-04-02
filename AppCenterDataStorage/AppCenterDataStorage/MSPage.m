// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPage.h"

@implementation MSPage

@synthesize error = _error;
@synthesize items = _items;

- (instancetype)initWithItems:(NSArray<MSDocumentWrapper *> *)items {
  if ((self = [super init])) {
    _items = items;
  }
  return self;
}

- (instancetype)initWithError:(MSDataSourceError *)error {
  if ((self = [super init])) {
    _error = error;
  }
  return self;
}

@end
