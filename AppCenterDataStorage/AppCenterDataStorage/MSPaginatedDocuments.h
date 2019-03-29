// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPage.h"
#import "MSReadOptions.h"
#import "MSSerializableDocument.h"

// A (paginated) list of documents from CosmosDB
@interface MSPaginatedDocuments<T : id <MSSerializableDocument>> : NSObject

// FIXME: these properties should not be part of the public interface.

/**
 * Current page.
 */
@property(nonatomic, strong, readonly) MSPage *currentPage;

/**
 * Partition.
 */
@property(nonatomic, strong, readonly) NSString *partition;

/**
 * Type of the documents.
 */
@property(nonatomic, strong, readonly) Class documentType;

/**
 * Read options.
 */
@property(nonatomic, strong, readonly) MSReadOptions *readOptions;

/**
 * Current continuation token if any.
 */
@property(nonatomic, strong, readonly, nullable) NSString *continuationToken;

/**
 * Initialize documents with page.
 *
 * @param page Page to instantiate documents with.
 * @param partition The partition for the documents.
 * @param documentType The type of the documents in the partition.
 * @param readOptions The read options.
 * @param continuationToken The continuation token, if any.
 *
 * @return The paginated documents.
 */
- (instancetype)initWithPage:(MSPage *)page
                   partition:(NSString *)partition
                documentType:(Class)documentType
                 readOptions:(MSReadOptions *_Nullable)readOptions
           continuationToken:(NSString *_Nullable)continuationToken;

/**
 * Initialize documents with page and nil continuation token.
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
 */
- (void)nextPageWithCompletionHandler:(void (^)(MSPage<T> *page))completionHandler;

@end
