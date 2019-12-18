// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "MSStorageBindableType.h"
#import <Foundation/Foundation.h>

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
- (void)addString:(NSString *)value;

/**
 * Adds a number object into array.
 * @param value NSNumber value to be added to the array.
 */
- (void)addNumber:(NSNumber *)value;

/**
 * Adds a null value to the array.
 */
- (void)addNullValue;

/**
 * Binds all values in an array with given sqlite statement.
 * @param query sqlite statement.
 * @param db reference to database.
 */
- (int)bindAllValuesWithStatement:(sqlite3_stmt *)query inOpenedDatabase:(void *)db;

@end
