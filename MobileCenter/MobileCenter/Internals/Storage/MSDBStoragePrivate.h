#import "MSDBStorage.h"

@class MSDatabaseConnection;

@interface MSDBStorage ()

@property (nonatomic) id<MSDatabaseConnection> connection;

/**
 * Get all logs with the given group ID from the storage.
 *
 * @param groupID The groupID used for grouping logs.
 *
 * @return Logs corresponding to the given group ID from the storage.
 *
 */
- (NSArray<MSLog>*) getLogsWithGroupID:(NSString*)groupID;

@end

