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

/**
 * For testing only. Initialize a transmission target with token, parent target and storage.
 *
 * @param token A transmission target token.
 * @param parentTarget Nested parent transmission target.
 * @param storage A storage to persist states of this transmission target.
 *
 * @return A transmission target instance.
 */
- (instancetype)initWithTransmissionTargetToken:(NSString *)token
                                   parentTarget:(nullable MSAnalyticsTransmissionTarget *)parentTarget
                                        storage:(MSUserDefaults *)storage;

@end

NS_ASSUME_NONNULL_END
