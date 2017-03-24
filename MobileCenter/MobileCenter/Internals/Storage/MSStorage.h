#import "MSLog.h"
#import "MSLogContainer.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^MSLoadDataCompletionBlock)(BOOL succeeded, NSArray<MSLog> *logArray, NSString *batchId);

/**
 * Defines the storage component which is responsible for file i/o and file management.
 */
@protocol MSStorage <NSObject>

/**
 * Defines the maximum count of app log files per storage key on the file system.
 *
 * Default: 7
 */
@property(nonatomic) NSUInteger bucketFileCountLimit;

/**
 * Defines the maximum count of app logs per storage key in a file.
 *
 * Default: 50
 */
@property(nonatomic) NSUInteger bucketFileLogCountLimit;

@required

/**
 * Writes a log to the file system.
 *
 * @param log The log item that should be written to disk
 * @param groupID The groupID used for grouping
 *
 * @return BOOL that indicates if the log was saved successfully.
 */
- (BOOL)saveLog:(id<MSLog>)log withGroupID:(NSString *)groupID;

/**
 * Delete logs related to given storage key from the file system.
 *
 * @param groupID The groupID used for grouping.
 *
 * @return the list of deleted logs.
 */
- (NSArray<MSLog> *)deleteLogsForGroupID:(NSString *)groupID;

/**
 * Delete a log from the file system.
 *
 * @param logsId The log item that should be deleted from disk.
 * @param groupID The key used for grouping.
 */
- (void)deleteLogsForId:(NSString *)logsId withGroupID:(NSString *)groupID;

/**
 * Returns the most recent logs for a given storage key.
 *
 * @param groupID The key used for grouping.
 *
 * @return a list of logs.
 */
- (BOOL)loadLogsForGroupID:(NSString *)groupID withCompletion:(nullable MSLoadDataCompletionBlock)completion;

/**
 * FIXME: The number of logs per batch and the number of logs per files are currently tied together. The storage loads
 * what's contained in the available file and this could be higher than the batch max size going to be sent. To mitigate
 * this kind of scenario the file is closed when the max size of the log batch is reached.
 *
 * @param groupID The key used for grouping.
 */
- (void)closeBatchWithGroupID:(NSString *)groupID;

@end

NS_ASSUME_NONNULL_END
