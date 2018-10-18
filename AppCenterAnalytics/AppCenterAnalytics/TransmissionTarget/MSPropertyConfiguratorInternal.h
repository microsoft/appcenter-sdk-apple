#import <Foundation/Foundation.h>

#import "MSChannelDelegate.h"
#import "MSEventPropertiesInternal.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSPropertyConfigurator () <MSChannelDelegate>

/**
 * Initialize property configurator with a transmission target.
 */
- (instancetype)initWithTransmissionTarget:(MSAnalyticsTransmissionTarget *)transmissionTarget;

/**
 * Merge typed properties.
 *
 * @param mergedEventProperties The destination event properties that merges current event properties to.
 */
- (void)mergeTypedPropertiesWith:(MSEventProperties *)mergedEventProperties;

NS_ASSUME_NONNULL_END

@end
