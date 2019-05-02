// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSPage ()

/**
 * Initialize a page with an array of documents.
 *
 * @param items The documents in a page.
 *
 * @return The page with documents.
 */
- (instancetype)initWithItems:(NSArray<MSDocumentWrapper *> *)items;

/**
 * Initialize a page with an error.
 *
 * @param error Error to initialize page with.
 *
 * @return The page with error.
 */
- (instancetype)initWithError:(MSDataError *)error;

@end

NS_ASSUME_NONNULL_END
