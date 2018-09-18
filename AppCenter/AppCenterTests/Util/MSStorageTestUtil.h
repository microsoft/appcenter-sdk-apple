#import <Foundation/Foundation.h>

@interface MSStorageTestUtil : NSObject

/**
 * The relative path to the DB.
 */
@property(nonatomic, copy) NSString *path;

/**
 * Custom init.
 *
 * @param fileName The file name of the db.
 *
 * @return The instance.
 */
- (instancetype)initWithDbFileName:(NSString *)fileName;

/**
 * Get the size of the data in the test db.
 *
 * @return tThe size of the data in the db.
 */
- (long)getDataLengthInBytes;

/**
 * Open the test database. Make sure to close the handle once you're done!
 *
 * @return The handle to the db.
 */
- (sqlite3 *)openDatabase;

@end
