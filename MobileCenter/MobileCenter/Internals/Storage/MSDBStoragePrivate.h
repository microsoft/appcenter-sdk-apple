#import "MSDBStorage.h"

@protocol MSDatabaseConnection;

@interface MSDBStorage ()

/**
 * Connection to SQLite database.
 */
@property(nonatomic) id<MSDatabaseConnection> connection;

/**
 * Keep track of logs batches per group Id associated with their logs Ids.
 */
@property(nonatomic) NSMutableDictionary<NSString *, NSArray<NSString *> *> *batches;

/**
 * Get all logs with the given group Id from the storage.
 *
 * @param groupId The key used for grouping logs.
 *
 * @return Logs corresponding to the given group Id from the storage.
 *
 */
- (NSDictionary<NSString *, id<MSLog>> *)getLogsFromDBWithGroupId:(NSString *)groupId;

@end
