#import "MSDBStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDBStorage ()

/**
 * Database file name.
 */
@property(nonatomic, readonly, nullable) NSURL *dbFileURL;

/**
 * Delete the database file, this can't be undone. Only used while testing.
 */
- (void)deleteDatabase;

/**
 *
 */
- (void)migrateDatabase:(void *)db fromVersion:(NSUInteger)version;

/**
 *
 */
- (BOOL)executeWithDatabase:(int (^)(void *))callback;

/**
 * Check if a table exists in this database.
 *
 * @param tableName Table name.
 *
 * @return `YES` if the table exists in the database, otherwise `NO`.
 */
+ (BOOL)tableExists:(NSString *)tableName inDatabase:(void *)db;

/**
 *
 */
+ (int)executeNonSelectionQuery:(NSString *)query inDatabase:(void *)db;

/**
 *
 */
+ (NSArray<NSArray *> *)executeSelectionQuery:(NSString *)query inDatabase:(void *)db;

@end

NS_ASSUME_NONNULL_END
