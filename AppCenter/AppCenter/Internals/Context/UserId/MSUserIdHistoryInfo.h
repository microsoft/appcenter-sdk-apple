#import "MSHistoryInfo.h"

/**
 * Model class that is intended to be used to correlate userId to a crash at app relaunch.
 */
@interface MSUserIdHistoryInfo : MSHistoryInfo

/**
 * User Id.
 */
@property(nonatomic, copy) NSString *userId;

/**
 * Initializes a new `MSUserIdHistoryInfo` instance.
 *
 * @param timestamp Timestamp.
 * @param userId User Id.
 */
- (instancetype)initWithTimestamp:(NSDate *)timestamp andUserId:(NSString *)userId;

@end
