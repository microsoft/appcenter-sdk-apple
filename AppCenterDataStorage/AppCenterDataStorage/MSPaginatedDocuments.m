#import "MSPaginatedDocuments.h"
#import "MSSerializableDocument.h"

@implementation MSPaginatedDocuments

- (BOOL)hasNextPage {
  // @todo
  return NO;
}

- (MSPage<id<MSSerializableDocument>> *)currentPage {
  // @todo
  return nil;
}

- (MSPage<id<MSSerializableDocument>> *)nextPageWithCompletionHandler:
    (void (^)(MSPage<id<MSSerializableDocument>> *page))completionHandler {
  // @todo
  (void)completionHandler;
  return nil;
}

@end
