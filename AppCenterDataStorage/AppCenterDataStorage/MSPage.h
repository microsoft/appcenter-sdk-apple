// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataSourceError.h"
#import "MSDocumentWrapper.h"
#import "MSSerializableDocument.h"

@interface MSPage<T : id <MSSerializableDocument>> : NSObject

/**
 * Error (or null).
 */
@property(readonly) MSDataSourceError *error;

/**
 * Array of documents in the current page (or null).
 */
@property(readonly) NSArray<MSDocumentWrapper<T> *> *items;

/**
 * Initialize a page with an error.
 *
 * @param items Error to initialize page with.
 *
 * @return The page with documents.
 */
- (instancetype)initWithItems:(NSArray<MSDocumentWrapper<T> *> *)items;

/**
 * Initialize a page with an error.
 *
 * @param error Error to initialize page with.
 *
 * @return The page with error.
 */
- (instancetype)initWithError:(MSDataSourceError *)error;

@end
