#import "MSLog.h"
#import "MSLogContainer.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^MSLoadDataCompletionBlock)(BOOL succeeded, NSArray<MSLog> *logArray, NSString *batchId);

/**
 * Defines the storage component which is responsible for persisting logs.
 */
@protocol MSStorage <NSObject>

@required

/**
 * Store a log.
 *
 * @param log The log to be stored.
 * @param groupID The groupID used for grouping logs.
 *
 * @return BOOL that indicates if the log was saved successfully.
 */
- (BOOL)saveLog:(id<MSLog>)log withGroupID:(NSString *)groupID;

/**
 * Delete logs related to given group from the storage.
 *
 * @param groupID The groupID used for grouping logs.
 *
 * @return The list of deleted logs.
 */
- (NSArray<MSLog> *)deleteLogsForGroupID:(NSString *)groupID;

/**
 * Delete a log from the storage.
 *
 * @param logsId The log that should be deleted from storage.
 * @param groupID The groupID used for grouping logs.
 */
- (void)deleteLogsForId:(NSString *)logsId withGroupID:(NSString *)groupID;

/**
 * Return the most recent logs for a Group Id.
 *
 * @param groupID The key used for grouping.
 * @param limit Limit the maximum number of logs to be loaded from the server.
 *
 * @return a list of logs.
 */
- (BOOL)loadLogsForGroupID:(NSString *)groupID limit:(NSUInteger)limit withCompletion:(nullable MSLoadDataCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
