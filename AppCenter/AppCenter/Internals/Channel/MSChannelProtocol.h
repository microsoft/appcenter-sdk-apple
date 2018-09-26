#import <Foundation/Foundation.h>

#import "MSEnable.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSChannelDelegate;

/**
 * `MSChannelProtocol` contains the essential operations of a channel. Channels
 * are broadly responsible for enqueuing logs to be sent to the backend and/or
 * stored on disk.
 */
@protocol MSChannelProtocol <NSObject, MSEnable>

/**
 * Add delegate.
 *
 * @param delegate delegate.
 */
- (void)addDelegate:(id<MSChannelDelegate>)delegate;

/**
 * Remove delegate.
 *
 * @param delegate delegate.
 */
- (void)removeDelegate:(id<MSChannelDelegate>)delegate;

/**
 * Pause operations, logs will be stored but not sent.
 *
 * @param token Token used to identify the pause request, can be any object.
 *
 * @discussion The same token must be used to call resume.
 *
 * @see resumeWithToken:
 */
- (void)pauseWithToken:(id <NSObject>)token;

/**
 * Resume operations, logs can be sent again.
 *
 * @param token Token used to passed to the pause method.
 *
 * @discussion The channel only resume when all the outstanding tokens have been resumed.
 *
 * @see pauseWithToken:
 */
- (void)resumeWithToken:(id <NSObject>)token;

@end

NS_ASSUME_NONNULL_END
