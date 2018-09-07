

#import <Foundation/Foundation.h>

#import "MSAnalyticsTransmissionTarget.h"
#import "MSChannelDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSPropertyConfigurator () <MSChannelDelegate>

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
 * Event properties attached to events tracked by this target.
 */
@property(nonatomic, nullable)
    NSMutableDictionary<NSString *, NSString *> *eventProperties;

/**
 * Initialize property configurator with a transmission target.
 */
- (instancetype)initWithTransmissionTarget:
    (MSAnalyticsTransmissionTarget *)transmissionTarget;

/**
 * The device id to send with common schema logs. If nil, nothing is sent.
 */
@property(nonatomic, copy) NSString *deviceId;

@end

NS_ASSUME_NONNULL_END
