#import "MSDataStoreError.h"
#import "MSPage.h"
#import "MSSerializableDocument.h"
#import <Foundation/Foundation.h>

// A (paginated) list of documents from CosmosDB
@interface MSPaginatedDocuments<T : id <MSSerializableDocument>> : NSObject

/**
 * Boolean indicating if an extra page is available.
 */
- (BOOL)hasNextPage;

/**
 * Return the current page
 */
- (MSPage<T> *)currentPage;

/**
 * Asynchronously fetch the next page
 */
- (MSPage<T> *)nextPageWithCompletionHandler:(void (^)(MSPage<T> *page))completionHandler;

@end
