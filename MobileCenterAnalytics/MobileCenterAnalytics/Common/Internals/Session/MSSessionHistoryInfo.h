#import <Foundation/Foundation.h>

@interface MSSessionHistoryInfo : NSObject <NSCoding>

/**
 * Initializes a new `MSSessionHistoryInfo` instance.
 *
 * @param toffset Time offset
 * @param sessionId Session Id
 */
- (instancetype)initWithTOffset:(NSNumber *)toffset andSessionId:(NSString *)sessionId;

/**
 *  Session Id.
 */
@property(nonatomic, copy) NSString *sessionId;

/**
 *  Time offset.
 */
@property(nonatomic) NSNumber *toffset;

@end
