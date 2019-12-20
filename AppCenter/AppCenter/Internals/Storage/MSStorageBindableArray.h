// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSStorageBindableType.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSStorageBindableArray : NSObject

/**
 * Custom array for storing values to be bound in an sqlite statement.
 * Accepts only supported types.
 */
@property(nonatomic) NSMutableArray<id<MSStorageBindableType>> *array;

/**
 * Adds a string object into array.
 * @param value NSString value to be added to the array.
 */
- (void)addString:(nullable NSString *)value;

/**
 * Adds a number object into array.
 * @param value NSNumber value to be added to the array.
 * Can not be nil since it means it's an error.
 */
- (void)addNumber:(NSNumber *)value;

/**
 * Binds all values in an array with given sqlite statement.
 * @param query sqlite statement.
 * @param db reference to database.
 */
- (int)bindAllValuesWithStatement:(void *)query inOpenedDatabase:(void *)db;

@end

NS_ASSUME_NONNULL_END
