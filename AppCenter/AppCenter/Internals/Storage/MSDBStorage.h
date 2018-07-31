#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * FIXME: We need ordered columns so we can't just use an `NSDictionary` to
 * store them. A workaround is to use an array of dictionaries instead, still
 * works fine as literals. But, we should use an array of tuples when we'll
 * switch to Swift.
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
typedef NSDictionary<
    NSString *, NSArray<NSDictionary<NSString *, NSArray<NSString *> *> *> *>
    MSDBSchema;

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
- (instancetype)initWithSchema:(MSDBSchema *)schema
                       version:(NSUInteger)version
                      filename:(NSString *)filename;

/**
 * Count entries on a given table using the given SQLite "WHERE" clause's
 * condition.
 *
 * @param tableName Name of the table to inspect.
 * @param condition The SQLite "WHERE" clause's condition.
 *
 * @return The count of entries for this query.
 */
- (NSUInteger)countEntriesForTable:(NSString *)tableName
                         condition:(nullable NSString *)condition;

/**
 * Execute a non selection SQLite query on the database (i.e.: "CREATE",
 * "INSERTE", "UPDATE"... but not "SELECT").
 *
 * @param query An SQLite query to execute.
 *
 * @return `YES` if the query executed successfully, otherwise `NO`.
 */
- (BOOL)executeNonSelectionQuery:(NSString *)query;

/**
 * Execute a "SELECT" SQLite query on the database.
 *
 * @param query An SQLite "SELECT" query to execute.
 *
 * @return The selectioned entries.
 */
- (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query;

/**
 * Get columns indexes from schema.
 *
 * @param schema Schema describing the database.
 *
 * @return Database tables columns indexes.
 */
+ (NSDictionary *)columnsIndexes:(MSDBSchema *)schema;

@end

NS_ASSUME_NONNULL_END
