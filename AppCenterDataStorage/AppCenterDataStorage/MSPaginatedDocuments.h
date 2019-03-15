#import "MSPage.h"
#import "MSSerializableDocument.h"

// A (paginated) list of documents from CosmosDB
@interface MSPaginatedDocuments : NSObject

/**
 * Boolean indicating if an extra page is available.
 */
- (BOOL)hasNextPage;

/**
 * Return the current page.
 *
 * @return The current page of documents.
 */
- (MSPage *)currentPage;

/**
 * Asynchronously fetch the next page.
 *
 * @param completionHandler Callback to accept the next page of documents.
 *
 * @return The next page of documents.
 */
- (MSPage *)nextPageWithCompletionHandler:(void (^)(MSPage *page))completionHandler;

@end
