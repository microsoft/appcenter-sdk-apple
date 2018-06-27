#import <Foundation/Foundation.h>

#import "MSAnalyticsTransmissionTarget.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAnalyticsTransmissionTarget ()

/**
 * Child transmission targets nested to this transmission target.
 */
@property(nonatomic) NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *> *childTransmissionTargets;

@end

NS_ASSUME_NONNULL_END
