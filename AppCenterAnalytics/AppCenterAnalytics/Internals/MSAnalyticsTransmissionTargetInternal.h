#import <Foundation/Foundation.h>

#import "MSAnalyticsTransmissionTarget.h"

@protocol MSChannelGroupProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface MSAnalyticsTransmissionTarget ()

/**
 * The transmission target token corresponding to this transmission target.
 */
@property(nonatomic, copy, readonly) NSString *transmissionTargetToken;

/**
 * Initialize a transmission target with token and parent target.
 *
 * @param token A transmission target token.
 * @param parentTarget Nested parent transmission target.
 * @param channelGroup The Channel group.
 *
 * @return A transmission target instance.
 */
- (instancetype)initWithTransmissionTargetToken:(NSString *)token
                                   parentTarget:(nullable MSAnalyticsTransmissionTarget *)parentTarget
                                   channelGroup:(nonnull id<MSChannelGroupProtocol>)channelGroup;

@end

NS_ASSUME_NONNULL_END
