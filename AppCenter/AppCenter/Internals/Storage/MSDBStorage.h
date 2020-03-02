// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSStorageBindableArray.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * FIXME: We need ordered columns so we can't just use an `NSDictionary` to store them. A workaround is to use an array of dictionaries
 * instead, still works fine as literals. But, we should use an array of tuples when we'll switch to Swift.
 *
 * Database schema example:
 *
 *        @{
 *           table_name : @[
 *             @{ column_name: @[ column_type, column_constraints, ... ]},
 *             ...
 *           ],
 *           ...
 *        };
 */
typedef NSArray<NSDictionary<NSString *, NSArray<NSString *> *> *> MSDBColumnsSchema;
typedef NSDictionary<NSString *, MSDBColumnsSchema *> MSDBSchema;

// SQLite types
static NSString *const kMSSQLiteTypeText = @"TEXT";
static NSString *const kMSSQLiteTypeInteger = @"INTEGER";

// SQLite column constraints.
static NSString *const kMSSQLiteConstraintNotNull = @"NOT NULL";
static NSString *const kMSSQLiteConstraintPrimaryKey = @"PRIMARY KEY";
static NSString *const kMSSQLiteConstraintAutoincrement = @"AUTOINCREMENT";

@interface MSDBStorage : NSObject

/**
 * Initialize this database with a schema and a filename for its creation.
 *
 * @param schema Schema describing the database.
 * @param version Version of the database.
 * @param filename Database filename in the file system.
 *
 * @return An instance of a database.
 */
- (instancetype)initWithSchema:(nullable MSDBSchema *)schema version:(NSUInteger)version filename:(NSString *)filename;

/**
 * Initialize this database with a version and a filename for its creation.
 *
 * @param version Version of the database.
 * @param filename Database filename in the file system.
 *
 * @return An instance of a database.
 */
- (instancetype)initWithVersion:(NSUInteger)version filename:(NSString *)filename;

/**
 * Count entries on a given table using the given SQLite "WHERE" clause's condition.
 *
 * @param tableName Name of the table to inspect.
 * @param condition The SQLite "WHERE" clause's condition.
 *
 * @return The count of entries for this query.
 */
- (NSUInteger)countEntriesForTable:(NSString *)tableName
                         condition:(nullable NSString *)condition
                        withValues:(nullable MSStorageBindableArray *)values;

/**
 * Execute a non selection SQLite query on the database (i.e.: "CREATE", "INSERT", "UPDATE"... but not "SELECT").
 *
 * @param query An SQLite query to execute.
 *
 * @return The SQLite return code.
 */
- (int)executeNonSelectionQuery:(NSString *)query;

/**
 * Execute a non selection SQLite query on the database (i.e.: "CREATE", "INSERT", "UPDATE"... but not "SELECT").
 *
 * @param query A SQLite query to execute.
 * @param values An array of query parameters to be substituted using `sqlite3_bind`.
 *
 * @return A result code for the query execution.
 */
- (int)executeNonSelectionQuery:(NSString *)query withValues:(nullable MSStorageBindableArray *)values;

/**
 * Execute a "SELECT" SQLite query on the database.
 *
 * @param query A SQLite "SELECT" query to execute.
 * @param values An array of query parameters to be substituted using `sqlite3_bind`.
 *
 * @return The selected entries.
 */
- (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query withValues:(nullable MSStorageBindableArray *)values;

/**
 * Get columns indexes from schema.
 *
 * @param schema Schema describing the database.
 *
 * @return Database tables columns indexes.
 */
+ (NSDictionary *)columnsIndexes:(MSDBSchema *)schema;

/**
 * Deletes database.
 *
 */
- (void)dropDatabase;

/**
 * Deletes table within an existing database.
 *
 * @param tableName Name of the table to delete.
 *
 * @return operation status.
 */
- (BOOL)dropTable:(NSString *)tableName;

/**
 * Set the maximum size of the internal storage. This method must be called before App Center is started.
 *
 * @param sizeInBytes Maximum size of the internal storage in bytes. This will be rounded up to the nearest multiple of a SQLite page size
 * (default is 4096 bytes). Values below 20,480 bytes (20 KiB) will be ignored.
 * @param completionHandler Callback that is invoked when the database size has been set. The `BOOL` parameter is `YES` if changing the size
 * is successful, and `NO` otherwise.
 *
 * @discussion This only sets the maximum size of the database, but App Center modules might store additional data.
 * The value passed to this method is not persisted on disk. The default maximum database size is 10485760 bytes (10 MiB).
 */
- (void)setMaxStorageSize:(long)sizeInBytes completionHandler:(nullable void (^)(BOOL))completionHandler;

@end

NS_ASSUME_NONNULL_END
