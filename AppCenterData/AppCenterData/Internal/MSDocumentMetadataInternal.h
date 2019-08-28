// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentMetadata.h"

@interface MSDocumentMetadata ()

/**
 * Initialize a `MSDocumentWrapper` instance.
 *
 * @param partition Partition key.
 * @param documentId Document id.
 * @param eTag Document eTag.
 *
 * @return A new `MSDocumentWrapper` instance.
 */
- (instancetype)initWithPartition:(NSString *)partition
                       documentId:(NSString *)documentId
                             eTag:(NSString *)eTag;
@end
