#import "MSDBStorage.h"

static NSString *const kMSLogEntityName = @"MSDBLog";
static NSString *const kMSDBFileName = @"MSDBLogs.sqlite";
static NSString *const kMSLogTableName = @"MSLog";
static NSString *const kMSIdColumnName = @"id";
static NSString *const kMSGroupIdColumnName = @"groupId";
static NSString *const kMSDataColumnName = @"data";
static NSString *const kMSBatchIdColumnName = @"batchId";

@protocol MSDatabaseConnection;

@interface MSDBStorage ()

/**
 * Maximum allowed capacity in this storage.
 */
@property(nonatomic, readonly) NSUInteger capacity;

/**
 * Connection to SQLite database.
 */
@property(nonatomic) id<MSDatabaseConnection> connection;

/**
 * Get all logs with the given group Id from the storage.
 *
 * @param groupId The key used for grouping logs.
 *
 * @return Logs corresponding to the given group Id from the storage.
 */
- (NSDictionary<NSString *, id<MSLog>> *)getLogsFromDBWithGroupId:(NSString *)groupId;

@end
