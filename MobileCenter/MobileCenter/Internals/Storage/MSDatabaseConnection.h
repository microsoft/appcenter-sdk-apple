#import <Foundation/Foundation.h>

@protocol MSDatabaseConnection <NSObject>

/**
 * Create a storage with a capacity.
 *
 * @param dbFilename Database filename.
 *
 * @return Return an instance of database connection.
 */
- (instancetype)initWithDatabaseFilename:(NSString *)dbFilename;

/**
 * Execute the given SQL query on the database.
 *
 * @param query SQL query to execute.
 *
 * @return Return `YES` if the query executed successfully, `NO` otherwise.
 */
- (BOOL)executeQuery:(NSString *)query;

/**
 * Select data from the database.
 *
 * @param query Select query to execute.
 *
 * @return An array representing the data in the database.
 */
- (NSArray<NSArray<NSString *> *> *)selectDataFromDB:(NSString *)query;

@end
