// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPaginatedDocuments.h"
#import "MSSerializableDocument.h"

@implementation MSPaginatedDocuments

@synthesize currentPage = _currentPage;
@synthesize continuationToken = _continuationToken;

- (instancetype)initWithPage:(MSPage *)page andContinuationToken:(nullable NSString *)continuationToken {
  if ((self = [super init])) {
    _currentPage = page;
    _continuationToken = continuationToken;
  }
  return self;
}

- (instancetype)initWithError:(MSDataSourceError *)error {
  if ((self = [super init])) {
    MSPage *pageWithError = [[MSPage alloc] initWithError:error];
    return [self initWithPage:pageWithError andContinuationToken:nil];
  }
  return self;
}

- (BOOL)hasNextPage {
  return !self.continuationToken.length;
}

- (MSPage<id<MSSerializableDocument>> *)nextPageWithCompletionHandler:
    (void (^)(MSPage<id<MSSerializableDocument>> *page))completionHandler {
  // @todo
  (void)completionHandler;
  return nil;
}

@end
