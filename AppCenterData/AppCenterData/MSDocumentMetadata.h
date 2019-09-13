// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSDocumentMetadata : NSObject

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

@end
