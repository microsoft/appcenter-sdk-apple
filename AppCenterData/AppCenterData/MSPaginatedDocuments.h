// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPage.h"
#import "MSReadOptions.h"
#import "MSSerializableDocument.h"

NS_ASSUME_NONNULL_BEGIN

// A (paginated) list of documents from CosmosDB
@interface MSPaginatedDocuments : NSObject

/**
 * Boolean indicating if an extra page is available.
 *
 * @return True if there is another page of documents, false otherwise.
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
 */
- (void)nextPageWithCompletionHandler:(void (^)(MSPage *page))completionHandler;

@end

NS_ASSUME_NONNULL_END
