// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSSerializableDocument.h"

@class MSDataSourceError;

@interface MSDocumentWrapper<T : id <MSSerializableDocument>> : NSObject

/**
 * Serialized document.
 */
@property(nonatomic, strong, readonly) NSString *jsonValue;

/**
 * Deserialized document.
 */
@property(nonatomic, strong, readonly) T deserializedValue;

/**
 * Cosmos Db document partition.
 */
@property(nonatomic, strong, readonly) NSString *partition;

/**
 * Document Id.
 */
@property(nonatomic, strong, readonly) NSString *documentId;

/**
 * Document eTag.
 */
@property(nonatomic, strong, readonly) NSString *eTag;

/**
 * Last update timestamp.
 */
@property(nonatomic, strong, readonly) NSDate *lastUpdatedDate;

/**
 * Document error.
 */
@property(nonatomic, strong, readonly) MSDataSourceError *error;

/**
 * Initialize a `MSDocumentWrapper` instance.
 *
 * @param error Document error.
 * @param documentId Document Id.
 *
 * @return A new `MSDocumentWrapper` instance.
 */
- (instancetype)initWithError:(NSError *)error documentId:(NSString *)documentId;

/**
 * Check if the document is from the device cache.
 *
 * @return Flag indicating if the document was retrieved
 * from the device cache instead of from CosmosDB.
 */
- (BOOL)fromDeviceCache;

@end
