#import <Foundation/Foundation.h>

@interface MSHistoryInfo : NSObject <NSCoding>

/**
 * Timestamp.
 */
@property(nonatomic) NSDate *timestamp;

/**
 * Initializes a new `MSHistoryInfo` instance.
 *
 * @param timestamp Timestamp
 */
- (instancetype)initWithTimestamp:(NSDate *)timestamp;

@end
