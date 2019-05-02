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

@end
