#import "MSLogDBStorage.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kMSLogEntityName = @"MSDBLog";
static NSString *const kMSDBFileName = @"Logs.sqlite";
static NSString *const kMSLogTableName = @"logs";
static NSString *const kMSIdColumnName = @"id";
static NSString *const kMSGroupIdColumnName = @"groupId";
static NSString *const kMSLogColumnName = @"log";

@protocol MSDatabaseConnection;

@interface MSLogDBStorage ()

/**
 * Maximum allowed capacity in this storage.
 */
@property(nonatomic, readonly) NSUInteger capacity;

/**
 * Keep track of logs batches per group Id associated with their logs Ids.
 */
@property(nonatomic) NSMutableDictionary<NSString *, NSArray<NSNumber *> *> *batches;

/**
 * Get all logs with the given group Id from the storage.
 *
 * @param groupId The key used for grouping logs.
 *
 * @return Logs and their ids corresponding to the given group Id from the storage.
 */
- (NSArray<id<MSLog>> *)logsFromDBWithGroupId:(NSString *)groupId;

@end

NS_ASSUME_NONNULL_END
