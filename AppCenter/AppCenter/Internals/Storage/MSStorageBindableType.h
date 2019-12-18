// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Defines the storage type to be bound in an sql statement.
 */
@protocol MSStorageBindableType <NSObject>

@required

/**
 * Binds itself with a statement.
 *
 * @param query sqlite statement.
 * @param index position of the parameter.
 *
 * @return int result code.
 */
- (int)bindWithStatement:(sqlite3_stmt *)query atIndex:(int)index;

@end

NS_ASSUME_NONNULL_END
