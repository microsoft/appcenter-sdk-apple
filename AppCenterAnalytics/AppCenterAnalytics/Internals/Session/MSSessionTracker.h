#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"
#import "MSSessionHistoryInfo.h"
#import "MSSessionTrackerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSSessionTracker : NSObject <MSChannelDelegate>

/**
 * Session tracker delegate.
 */
@property(nonatomic) id<MSSessionTrackerDelegate> delegate;

/**
 * Session timeout time.
 */
@property(nonatomic) NSTimeInterval sessionTimeout;

/**
 * Timestamp of the last created log.
 */
@property(nonatomic) NSDate *lastCreatedLogTime;

/**
 * Timestamp of the last time that the app entered foreground.
 */
@property(nonatomic) NSDate *lastEnteredForegroundTime;

/**
 * Timestamp of the last time that the app entered background.
 */
@property(nonatomic) NSDate *lastEnteredBackgroundTime;

/**
 * Start session tracking.
 */
- (void)start;

/**
 * Stop session tracking.
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
