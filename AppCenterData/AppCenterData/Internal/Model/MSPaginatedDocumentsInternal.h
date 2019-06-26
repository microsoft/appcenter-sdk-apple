// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPaginatedDocuments.h"

@class MSPage;

NS_ASSUME_NONNULL_BEGIN

@interface MSPaginatedDocuments ()

// Read-only.
@property(nonatomic, copy, readonly) NSString *partition;
@property(nonatomic, readonly) Class documentType;
@property(nonatomic) MS_Reachability *reachability;
@property(nonatomic, readonly) NSInteger deviceTimeToLive;

// Read-write (to implement pagination).
@property(nonatomic) MSPage *currentPage;
@property(nonatomic, copy, nullable) NSString *continuationToken;

/**
 * Initialize documents with page.
 *
 * @param page Page to instantiate documents with.
 * @param partition The partition for the documents.
 * @param documentType The type of the documents in the partition.
 * @param reachability The reachability module.
 * @param deviceTimeToLive Device document time to live in seconds.
 * @param continuationToken The continuation token, if any.
 *
 * @return The paginated documents.
 */
- (instancetype)initWithPage:(MSPage *)page
                   partition:(NSString *)partition
                documentType:(Class)documentType
                reachability:(MS_Reachability *)reachability
            deviceTimeToLive:(NSInteger)deviceTimeToLive
           continuationToken:(NSString *_Nullable)continuationToken;

/**
 * Initialize documents with a single page containing a document error.
 *
 * @param error Error to initialize with.
 * @param partition The partition for the documents.
 * @param documentType The type of the documents in the partition.
 *
 * @return The paginated documents.
 */
- (instancetype)initWithError:(MSDataError *)error partition:(NSString *)partition documentType:(Class)documentType;

@end

NS_ASSUME_NONNULL_END
