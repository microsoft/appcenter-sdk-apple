// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPaginatedDocuments.h"
#import "MSSerializableDocument.h"

@implementation MSPaginatedDocuments

@synthesize currentPage = _currentPage;

- (instancetype)initWithPage:(MSPage *)page {
  if ((self = [super init])) {
    _currentPage = page;
  }
  return self;
}

- (instancetype)initWithError:(MSDataSourceError *)error {
  if ((self = [super init])) {
    MSPage *pageWithError = [[MSPage alloc] initWithError:error];
    return [self initWithPage:pageWithError];
  }
  return self;
}

- (BOOL)hasNextPage {
  // @todo
  return NO;
}

- (MSPage<id<MSSerializableDocument>> *)currentPage {
  return _currentPage;
}

- (MSPage<id<MSSerializableDocument>> *)nextPageWithCompletionHandler:
    (void (^)(MSPage<id<MSSerializableDocument>> *page))completionHandler {
  // @todo
  (void)completionHandler;
  return nil;
}

@end
