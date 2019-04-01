// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDBStorage.h"
#import "MSDataStore.h"
#import "MSDocumentStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDBDocumentStore : NSObject <MSDocumentStore>

/**
 * Get table schema.
 *
 * @return Table schema.
 */
+ (NSArray<NSDictionary<NSString *, NSArray<NSString *> *> *> *)tableSchema;

@end

NS_ASSUME_NONNULL_END
