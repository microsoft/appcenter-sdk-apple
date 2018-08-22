#import <Foundation/Foundation.h>

#import "MSSessionHistoryInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSSessionContext : NSObject

/**
 * The current session info.
 */
@property(nonatomic) MSSessionHistoryInfo *currentSessionInfo;

/**
 * The session history that contains session Id and timestamp as an item.
 */
@property(nonatomic) NSMutableArray<MSSessionHistoryInfo *> *sessionHistory;

/**
 * Get singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 * Set current session Id.
 *
 * @param sessionId The session Id.
 */
- (void)setSessionId:(nullable NSString *)sessionId;

/**
 * Get current session Id.
 *
 * @return The current session Id.
 */
- (NSString *)sessionId;

/**
 * Get session Id at specific time.
 *
 * @param date The timestamp for the ssession.
 *
 * @return The session Id at the given time.
 */
- (nullable NSString *)sessionIdAt:(NSDate *)date;

/**
 * Clear all session Id history.
 */
- (void)clearSessionHistory;

@end

NS_ASSUME_NONNULL_END
