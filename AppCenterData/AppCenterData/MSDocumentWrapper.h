// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSSerializableDocument.h"

@class MSDataError;

@interface MSDocumentWrapper : NSObject

/**
 * Serialized document.
 */
@property(nonatomic, strong, readonly) NSString *jsonValue;

/**
 * Deserialized document.
 */
@property(nonatomic, strong, readonly) id<MSSerializableDocument> deserializedValue;

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
@property(nonatomic, strong, readonly) MSDataError *error;

/**
 * Flag indicating if a document was obtained from the local device store/cache
 * (as opposed to remotely by talking to CosmosDB).
 *
 * Note: The flag is always set to NO if the document is in an error state.
 */
@property(nonatomic, readonly, assign) BOOL fromDeviceCache;

@end
