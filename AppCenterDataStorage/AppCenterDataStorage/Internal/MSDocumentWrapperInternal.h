// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentWrapper.h"

@interface MSDocumentWrapper ()

/**
 * The type of pending operation, if any, that must be synchronized.
 */
@property(nonatomic) BOOL hasPendingOperation;

@end
