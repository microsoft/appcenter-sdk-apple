#import <Foundation/Foundation.h>

@interface MSSessionHistoryInfo : NSObject <NSCoding>

/**
 *  Session Id.
 */
@property(nonatomic, copy) NSString *sessionId;

/**
 *  Time offset.
 */
@property(nonatomic) NSNumber *toffset;

@end
