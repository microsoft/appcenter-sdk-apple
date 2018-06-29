#import <Foundation/Foundation.h>
#import "MSAnalyticsTransmissionTarget.h"

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
 *
 * @return A transmission target instance.
 */
- (instancetype)initWithTransmissionTargetToken:(NSString *)token
                                   parentTarget:(nullable MSAnalyticsTransmissionTarget *)parentTarget;

@end
