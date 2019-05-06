// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentWrapper.h"

@interface MSDocumentWrapper ()

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
 * @param fromDeviceCache Flag indicating if the document wrapper was retrieved remotely or not.
 *
 * @return A new `MSDocumentWrapper` instance.
 */
- (instancetype)initWithDeserializedValue:(id<MSSerializableDocument>)deserializedValue
                                jsonValue:(NSString *)jsonValue
                                partition:(NSString *)partition
                               documentId:(NSString *)documentId
                                     eTag:(NSString *)eTag
                          lastUpdatedDate:(NSDate *)lastUpdatedDate
                         pendingOperation:(NSString *)pendingOperation
                          fromDeviceCache:(BOOL)fromDeviceCache;

/**
 * Initialize a `MSDocumentWrapper` instance.
 *
 * @param error Document error.
 * @param partition Partition key.
 * @param documentId Document Id.
 *
 * @return A new `MSDocumentWrapper` instance.
 */
- (instancetype)initWithError:(MSDataError *)error partition:(NSString *)partition documentId:(NSString *)documentId;

/**
 * Initialize a `MSDocumentWrapper` instance.
 *
 * @param error Document error.
 * @param partition Partition key.
 * @param documentId Document Id.
 * @param eTag Document eTag.
 *
 * @return A new `MSDocumentWrapper` instance.
 */
- (instancetype)initWithError:(MSDataError *)error partition:(NSString *)partition documentId:(NSString *)documentId eTag:(NSString *)eTag;

/**
 * Initialize a `MSDocumentWrapper` instance.
 *
 * @param error Document error.
 * @param partition Partition key.
 * @param documentId Document Id.
 * @param eTag Document eTag.
 * @param lastUpdatedDate Last updated date of the document.
 * @param pendingOperation The name of the pending operation, or nil.
 * @param fromDeviceCache Flag indicating if the document wrapper was retrieved remotely or not.
 *
 * @return A new `MSDocumentWrapper` instance.
 */
- (instancetype)initWithError:(MSDataError *)error
                    partition:(NSString *)partition
                   documentId:(NSString *)documentId
                         eTag:(NSString *)eTag
              lastUpdatedDate:(NSDate *)lastUpdatedDate
             pendingOperation:(NSString *)pendingOperation
              fromDeviceCache:(BOOL)fromDeviceCache;

/**
 * The type of pending operation, if any, that must be synchronized.
 */
@property(nonatomic, copy) NSString *pendingOperation;

@end
