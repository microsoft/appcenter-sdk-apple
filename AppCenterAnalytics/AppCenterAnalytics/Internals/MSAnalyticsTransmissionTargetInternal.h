#import <Foundation/Foundation.h>
#import "MSAnalyticsTransmissionTarget.h"

@interface MSAnalyticsTransmissionTarget ()

/**
 * The transmission target token corresponding to this transmission target.
 */
@property(nonatomic, readonly) NSString *transmissionTargetToken;

- (instancetype)initWithTransmissionTargetToken:(NSString *)token parentTarget:(MSAnalyticsTransmissionTarget *)parentTarget;

@end
