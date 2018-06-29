#import <Foundation/Foundation.h>

#import "MSEnable.h"
#import "MSHttpSender.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSChannelDelegate;

/**
 * `MSChannelProtocol` contains the essential operations of a channel. Channels are
 * broadly responsible for enqueuing logs to be sent to the backend and/or stored
 * on disk.
 */
@protocol MSChannelProtocol <NSObject, MSEnable>

/**
 * TODO: This is temporarily moved from `MSChannelUnitDefault.h`. Move this back to original class once sender refactoring is merged.
 * A sender instance that is used to send batches of log items to the backend.
 */
@property(nonatomic, nullable) MSHttpSender *sender;

/**
 *  Add delegate.
 *
 *  @param delegate delegate.
 */
- (void)addDelegate:(id<MSChannelDelegate>)delegate;

/**
 *  Remove delegate.
 *
 *  @param delegate delegate.
 */
- (void)removeDelegate:(id<MSChannelDelegate>)delegate;

/**
 * Suspend operations, logs will be stored but not sent.
 */
- (void)suspend;

/**
 * Resume operations, logs can be sent again.
 */
- (void)resume;

/**
 * Set the app secret.
 *
 * @param appSecret The app secret.
 *
 * @discussion The app secret should be a property on MSChannelProtocol with synthesize statements in
 * MSDefaultChannelGroup and MSDefaultChannelUnit with MSDefaultChannelGroup having the custom setter (setAppSecret:).
 * The problem is that the compiler somehow doesn't "understand" that setAppSecret: is a setter, and it throws a warning
 * because we're accessing the ivar directly. 
 */
- (void)setAppSecret:(NSString *)appSecret;

@end

NS_ASSUME_NONNULL_END
