// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentWrapper.h"

@interface MSDocumentWrapper <T : id <MSSerializableDocument>>()

/**
 * Initialize a `MSDocumentWrapper` instance.
 *
 * @param deserializedValue The document value. Must conform to MSSerializableDocument protocol.
 * @param jsonValue The document's JSON representation.
 * @param partition Partition key.
 * @param documentId Document id.
 * @param eTag Document eTag.
 * @param lastUpdatedDate Last updated date of the document.
 * @param pendingOperation The name of the pending operation, or nil.
 * @param error An error.
 *
 * @return A new `MSDocumentWrapper` instance.
 */
- (instancetype)initWithDeserializedValue:(T)deserializedValue
                                jsonValue:(NSString *)jsonValue
                                partition:(NSString *)partition
                               documentId:(NSString *)documentId
                                     eTag:(NSString *)eTag
                          lastUpdatedDate:(NSDate *)lastUpdatedDate
                         pendingOperation:(nullable NSString *)pendingOperation
                                    error:(MSDataSourceError *)error;

/**
 * The type of pending operation, if any, that must be synchronized.
 */
@property(nonatomic, copy) NSString *pendingOperation;

@end
