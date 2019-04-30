// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPageInternal.h"

@implementation MSPage

@synthesize error = _error;
@synthesize items = _items;

- (instancetype)initWithItems:(NSArray<MSDocumentWrapper *> *)items {
  return [self initWithItems:items error:nil];
}

- (instancetype)initWithError:(MSDataError *)error {
  return [self initWithItems:nil error:error];
}

- (instancetype)initWithItems:(NSArray<MSDocumentWrapper *> *)items error:(MSDataError *)error {
  if ((self = [super init])) {
    _items = items;
    _error = error;
  }
  return self;
}

@end
