#import <Foundation/Foundation.h>

#import "MSAnalyticsTransmissionTarget.h"
#import "MSUtility.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAnalyticsTransmissionTarget ()

/**
 * Parent transmission target of this target.
 */
@property(nonatomic, nullable) MSAnalyticsTransmissionTarget *parentTarget;

/**
 * Child transmission targets nested to this transmission target.
 */
@property(nonatomic) NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *> *childTransmissionTargets;

/**
 * Storage used for persistence.
 */
@property(nonatomic) MSUserDefaults *storage;

/**
 * isEnabled value storage key.
 */
@property(nonatomic, readonly) NSString *isEnabledKey;

@end

NS_ASSUME_NONNULL_END
