#import "MSDBStorage.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kMSStorageDirectory = @"com.microsoft.azure.mobile.mobilecenter";

@interface MSDBStorage ()

/**
 * Database absolute file path on the device's file system.
 */
@property(nonatomic, readonly, copy, nullable) NSString *filePath;

/**
 * Check if a table exists in this database.
 *
 * @param tableName Table name.
 *
 * @return `YES` if the table exists in the database, otherwise `NO`.
 */
- (BOOL)tableExists:(NSString *)tableName;

/**
 * Delete the database file, this can't be undone. Only used while testing.
 */
- (void)deleteDB;

@end

NS_ASSUME_NONNULL_END
