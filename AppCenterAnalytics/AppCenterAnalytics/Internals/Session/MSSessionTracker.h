#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"
#import "MSSessionHistoryInfo.h"
#import "MSSessionTrackerDelegate.h"

@interface MSSessionTracker : NSObject <MSLogManagerDelegate>

/**
 *  Session tracker delegate.
 */
@property(nonatomic) id<MSSessionTrackerDelegate> delegate;

/**
 * Current session id.
 */
@property(nonatomic, copy, readonly) NSString *sessionId;

/**
 *  Session timeout time.
 */
@property(nonatomic) NSTimeInterval sessionTimeout;

/**
 * Timestamp of the last created log.
 */
@property(nonatomic) NSDate *lastCreatedLogTime;

/**
 *  Timestamp of the last time that the app entered foreground.
 */
@property(nonatomic) NSDate *lastEnteredForegroundTime;

/**
 *  Timestamp of the last time that the app entered background.
 */
@property(nonatomic) NSDate *lastEnteredBackgroundTime;

/**
 *  Sorted array of session histories.
 */
@property(nonatomic) NSMutableArray<MSSessionHistoryInfo *> *pastSessions;

/**
 *  Start session tracking.
 */
- (void)start;

/**
 *  Stop session tracking.
 */
- (void)stop;

/**
 *  Clear cached sessions.
 */
- (void)clearSessions;

@end
