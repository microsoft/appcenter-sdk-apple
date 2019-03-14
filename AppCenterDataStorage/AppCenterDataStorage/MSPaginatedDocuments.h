#import "MSPage.h"
#import "MSSerializableDocument.h"

// A (paginated) list of documents from CosmosDB
@interface MSPaginatedDocuments<T : id <MSSerializableDocument>> : NSObject

/**
 * Boolean indicating if an extra page is available.
 */
- (BOOL)hasNextPage;

/**
 * Return the current page.
 *
 * @return The current page of documents.
 */
- (MSPage<T> *)currentPage;

/**
 * Asynchronously fetch the next page.
 *
 * @param completionHandler Callback to accept the next page of documents.
 *
 * @return The next page of documents.
 */
- (MSPage<T> *)nextPageWithCompletionHandler:(void (^)(MSPage<T> *page))completionHandler;

@end
