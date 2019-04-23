// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSBaseOptions.h"
#import "MSDBStorage.h"
#import "MSDocumentStore.h"
#import "MSDocumentWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDBDocumentStore : NSObject <MSDocumentStore>

/**
 * Create an instance of document store.
 *
 * @param dbStorage Database storage clinet.
 *
 * @return An intance of document store.
 */
- (instancetype)initWithDbStorage:(MSDBStorage *)dbStorage;

/**
 * Get column schema.
 *
 * @return Column schema.
 */
+ (MSDBColumnsSchema *)columnsSchema;

@end

NS_ASSUME_NONNULL_END
