#import <Foundation/Foundation.h>

#import "MSAnalyticsTransmissionTarget.h"

@class MSTypedProperty;

NS_ASSUME_NONNULL_BEGIN

@interface MSPropertyConfigurator ()

/**
 * The application version to be overwritten.
 */
@property(nonatomic, copy) NSString *appVersion;

/**
 * The application name to be overwritten.
 */
@property(nonatomic, copy) NSString *appName;

/**
 * The application locale to be overwritten.
 */
@property(nonatomic, copy) NSString *appLocale;

/**
 * The userId to be overwritten.
 */
@property(nonatomic, copy) NSString *userId;

/**
 * The transmission target which will have overwritten properties.
 */
@property(nonatomic, weak) MSAnalyticsTransmissionTarget *transmissionTarget;

/**
 * Event properties attached to events tracked by this target.
 */
@property(nonatomic) MSEventProperties *eventProperties;

/**
 * The device id to send with common schema logs. If nil, nothing is sent.
 */
@property(nonatomic, copy) NSString *deviceId;

@end

NS_ASSUME_NONNULL_END
