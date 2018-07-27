#import <Foundation/Foundation.h>

@interface MSSessionHistoryInfo : NSObject <NSCoding>

/**
 * Initializes a new `MSSessionHistoryInfo` instance.
 *
 * @param timestamp Timestamp
 * @param sessionId Session Id
 */
- (instancetype)initWithTimestamp:(NSDate *)timestamp
                     andSessionId:(NSString *)sessionId;

/**
 *  Session Id.
 */
@property(nonatomic, copy) NSString *sessionId;

/**
 *  Timestamp.
 */
@property(nonatomic) NSDate *timestamp;

@end
