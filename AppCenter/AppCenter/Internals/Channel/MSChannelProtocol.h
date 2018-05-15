#import <Foundation/Foundation.h>

#import "MSEnable.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSChannelDelegate;
@protocol MSChannelPersistDelegate;

/**
 * `MSChannelProtocol` contains the essential operations of a channel. Channels are
 * broadly responsible for enqueuing logs to be sent to the backend and/or stored
 * on disk.
 */
@protocol MSChannelProtocol <NSObject, MSEnable>

/**
 * A persist delegate.
 */
@property(nonatomic, nullable) id<MSChannelPersistDelegate> persistDelegate;

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

@end

NS_ASSUME_NONNULL_END
