#import "MSPaginatedDocuments.h"
#import "MSSerializableDocument.h"
#import "MSSerializableObject.h"
#import <Foundation/Foundation.h>

@implementation MSPaginatedDocuments

/**
 * Boolean indicating if an extra page is available.
 */
- (BOOL)hasNextPage {
  return NO;
}

/**
 * Return the current page
 */
- (MSPage<id<MSSerializableDocument>> *)currentPage {
  return nil;
}

/**
 * Asynchronously fetch the next page
 */
- (MSPage<id<MSSerializableDocument>> *)nextPageWithCompletionHandler:
    (void (^)(MSPage<id<MSSerializableDocument>> *page))completionHandler {
  (void)completionHandler;
  return nil;
}

@end
