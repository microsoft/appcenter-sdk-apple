#import "MSHistoryInfo.h"

/**
 * Model class that is intended to be used to correlate sessionId to a crash at app relaunch.
 */
@interface MSSessionHistoryInfo : MSHistoryInfo

/**
 * Session Id.
 */
@property(nonatomic, copy) NSString *sessionId;

/**
 * Initializes a new `MSSessionHistoryInfo` instance.
 *
 * @param timestamp Timestamp.
 * @param sessionId Session Id.
 */
- (instancetype)initWithTimestamp:(NSDate *)timestamp andSessionId:(NSString *)sessionId;

@end
