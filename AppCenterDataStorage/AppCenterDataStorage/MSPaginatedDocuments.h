// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPage.h"
#import "MSSerializableDocument.h"

// A (paginated) list of documents from CosmosDB
@interface MSPaginatedDocuments<T : id <MSSerializableDocument>> : NSObject

/**
 * Current page
 */
@property(nonatomic, strong, readonly) MSPage *currentPage;

/**
 * Initialize documents with page
 *
 * @param page Page to instantiate documents with.
 *
 * @return The paginated documents.
 */
- (instancetype)initWithPage:(MSPage *)page;

/**
 * Instantiate paginated Documents with single page with error.
 *
 * @param error Error to initialize with.
 *
 * @return The paginated documents.
 */
- (instancetype)initWithError:(MSDataSourceError *)error;

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
