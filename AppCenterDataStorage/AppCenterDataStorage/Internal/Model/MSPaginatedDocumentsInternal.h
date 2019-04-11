// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPage.h"
#import "MSReadOptions.h"

@interface MSPaginatedDocuments ()

// Read-only.
@property(nonatomic, copy, readonly, nullable) NSString *partition;
@property(nonatomic, readonly, nullable) Class documentType;
@property(nonatomic, readonly, nullable) MSReadOptions *readOptions;

// Read-write (to implement pagination).
@property(nonatomic, nonnull) MSPage *currentPage;
@property(nonatomic, copy, nullable) NSString *continuationToken;

@end
