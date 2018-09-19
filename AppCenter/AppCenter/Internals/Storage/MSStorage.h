#import <Foundation/Foundation.h>

#import "MSLog.h"
#import "MSLogContainer.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Completion block triggered when data is loaded from the storage.
 *
 * @param logArray Array of logs loaded from the storage.
 * @param batchId Batch Id associated with the logs, `nil` if no logs available.
 */
typedef void (^MSLoadDataCompletionBlock)(
    NSArray<id<MSLog>> *_Nullable logArray, NSString *_Nullable batchId);

/**
 * Defines the storage component which is responsible for persisting logs.
 */
@protocol MSStorage <NSObject>

@required

/**
 * Store a log.
 *
 * @param log The log to be stored.
 * @param groupId The key used for grouping logs.
 *
 * @return BOOL that indicates if the log was saved successfully.
 */
- (BOOL)saveLog:(id<MSLog>)log withGroupId:(NSString *)groupId;

/**
 * Delete logs related to given group from the storage.
 *
 * @param groupId The key used for grouping logs.
 *
 * @return The list of deleted logs.
 */
- (NSArray<id<MSLog>> *)deleteLogsWithGroupId:(NSString *)groupId;

/**
 * Delete a log from the storage.
 *
 * @param batchId Id of the log to be deleted from storage.
 * @param groupId The key used for grouping logs.
 */
- (void)deleteLogsWithBatchId:(NSString *)batchId groupId:(NSString *)groupId;

/**
 * Return the most recent logs for a Group Id.
 *
 * @param groupId The key used for grouping.
 * @param limit Limit the maximum number of logs to be loaded from disk.
 *
 * @return a list of logs.
 */
- (BOOL)loadLogsWithGroupId:(NSString *)groupId
                      limit:(NSUInteger)limit
             withCompletion:(nullable MSLoadDataCompletionBlock)completion;

/**
 * Set the maximum size of the internal storage. This method must be called
 * before App Center is started.
 *
 * @discussion  The value passed to this method is not persisted on disk. The
 * default maximum database size is 10485760 bytes (10 MiB).
 *
 * @param sizeInBytes Maximum size of in bytes. This will be rounded up to
 * the nearest multiple of 4096. Values below 20480 (20 KiB) will be ignored.
 * @param completionHandler Callback that is invoked when the database size
 * has been set. The `BOOL` parameter is `YES` if changing the size is
 * successful, and `NO` otherwise.
 */
- (void)setStorageSize:(long)sizeInBytes completionHandler:(void (^)(BOOL))
completionHandler;

@end

NS_ASSUME_NONNULL_END
