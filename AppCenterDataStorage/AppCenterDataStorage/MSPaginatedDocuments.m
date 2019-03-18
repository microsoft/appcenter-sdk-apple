#import "MSAbstractDocument.h"
#import "MSPaginatedDocuments.h"

@implementation MSPaginatedDocuments

- (BOOL)hasNextPage {
  // @todo
  return NO;
}

- (MSPage *)currentPage {
  // @todo
  return nil;
}

- (MSPage *)nextPageWithCompletionHandler:(void (^)(MSPage *page))completionHandler {
  // @todo
  (void)completionHandler;
  return nil;
}

@end
