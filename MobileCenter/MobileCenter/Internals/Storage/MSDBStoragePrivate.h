#import "MSDBStorage.h"

@protocol MSDatabaseConnection;

@interface MSDBStorage ()

@property(nonatomic) id<MSDatabaseConnection> connection;

/**
 * Get all logs with the given group Id from the storage.
 *
 * @param groupId The key used for grouping logs.
 *
 * @return Logs corresponding to the given group Id from the storage.
 *
 */
- (NSArray<MSLog> *)getLogsWithGroupId:(NSString *)groupId;

@end
