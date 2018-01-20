#import <Foundation/Foundation.h>

#import "MSEnable.h"

@class MSChannelDelegate;

/**
 * TODO add some comments
 */
@protocol MSChannelProtocol <NSObject, MSEnable>

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

//TODO needed? or should this be in channelgroupprotocol?
/**
 * Suspend operations, logs will not be sent but still stored.
 */
- (void)suspend;

/**
 * Resume operations, logs can be sent again.
 */
- (void)resume;

@end
