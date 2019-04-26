// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataError.h"
#import "MSDocumentWrapper.h"
#import "MSSerializableDocument.h"

@interface MSPage : NSObject

/**
 * Error (or null).
 */
@property(readonly) MSDataError *error;

/**
 * Array of documents in the current page (or null).
 */
@property(readonly) NSArray<MSDocumentWrapper *> *items;

/**
 * Initialize a page with an array of documents.
 *
 * @param items The documents in a page.
 *
 * @return The page with documents.
 */
- (instancetype)initWithItems:(NSArray<MSDocumentWrapper *> *)items; // TODO move to internal

/**
 * Initialize a page with an error.
 *
 * @param error Error to initialize page with.
 *
 * @return The page with error.
 */
- (instancetype)initWithError:(MSDataError *)error; // TODO move to internal

@end
