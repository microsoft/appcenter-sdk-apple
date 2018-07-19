#import <Foundation/Foundation.h>

#import "MSAnalyticsTransmissionTarget.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSPropertyConfigurator ()

/**
 * The application version to be overriden.
 */
@property(nonatomic, copy) NSString *appVersion;

/**
 * The application name to be overriden.
 */
@property(nonatomic, copy) NSString *appName;

/**
 * The application locale to be overriden.
 */
@property(nonatomic, copy) NSString *appLocale;

/**
 * The transmission target which will have overriden properties.
 */
@property(nonatomic, weak) MSAnalyticsTransmissionTarget *transmissionTarget;

/**
 * Initialize property configurator with a transmission target.
 */
- (instancetype)initWithTransmissionTarget:(MSAnalyticsTransmissionTarget *)transmissionTarget;

@end

NS_ASSUME_NONNULL_END
