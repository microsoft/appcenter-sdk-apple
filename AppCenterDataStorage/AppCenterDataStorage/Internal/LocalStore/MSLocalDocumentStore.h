// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDBStorage.h"
#import "MSDataStore.h"

@interface MSLocalDocumentStore : MSDBStorage

/**
 * Delete table.
 *
 * @param partition The partition name.
 */
- (BOOL)deleteTableWithPartition:(NSString *)partition;

/**
 * Create table.
 *
 * @param tableName Table name.
 */
- (void)createTableWithTableName:(NSString *)tableName;

/**
 * Get table schema.
 *
 * @return Table schema.
 */
+ (NSArray<NSDictionary<NSString *, NSArray<NSString *> *> *> *)tableSchema;

/**
 * Get table name by partition.
 *
 * @return Table name.
 */
+ (NSString *)tableNameWithPartition:(NSString *)partition;
@end
