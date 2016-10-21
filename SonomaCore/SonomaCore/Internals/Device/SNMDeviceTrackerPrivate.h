/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMDevice.h"
#import "SNMWrapperSdk.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>

@interface SNMDeviceTracker ()

/**
 *  Get the SDK version.
 *
 *  @param  version SDK version as const char.
 *
 *  @return The SDK version as an NSString.
 */
- (NSString *)sdkVersion:(const char[])version;

/**
 *  Get device model.
 *
 *  @return The device model as an NSString.
 */
- (NSString *)deviceModel;

/**
 *  Get the OS name.
 *
 *  @param device Current UIDevice.
 *
 *  @return The OS name as an NSString.
 */
- (NSString *)osName:(UIDevice *)device;

/**
 *  Get the OS version.
 *
 *  @param device Current UIDevice.
 *
 *  @return The OS version as an NSString.
 */
- (NSString *)osVersion:(UIDevice *)device;

/**
 *  Get the device current locale.
 *
 *  @param locale Device current locale.
 *
 *  @return The device current locale as an NSString.
 */
- (NSString *)locale:(NSLocale *)deviceLocale;

/**
 *  Get the device current timezone offset (UTC as reference).
 *
 *  @param timeZone Device timezone.
 *
 *  @return The device current timezone offset as an NSNumber.
 */
- (NSNumber *)timeZoneOffset:(NSTimeZone *)timeZone;

/**
 *  Get the renedered screen size.
 *
 *  @return The size of the screen as an NSString with format "HeightxWidth".
 */
- (NSString *)screenSize;

/**
 *  Get the network carrier name.
 *
 *  @param carrier Network carrier.
 *
 *  @return The network carrier name as an NSString.
 */
- (NSString *)carrierName:(CTCarrier *)carrier;

/**
 *  Get the network carrier country.
 *
 *  @param carrier Network carrier.
 *
 *  @return The network carrier country as an NSString.
 */
- (NSString *)carrierCountry:(CTCarrier *)carrier;

/**
 *  Get the application version.
 *
 *  @param appBundle Application main bundle.
 *
 *  @return The application version as an NSString.
 */
- (NSString *)appVersion:(NSBundle *)appBundle;

/**
 *  Get the application build.
 *
 *  @param appBundle Application main bundle.
 *
 *  @return The application build as an NSString.
 */
- (NSString *)appBuild:(NSBundle *)appBundle;

/**
 *  Get the application bundle ID.
 *
 *  @param appBundle Application main bundle.
 *
 *  @return The application bundle ID as an NSString.
 */
- (NSString *)appNamespace:(NSBundle *)appBundle;

/**
 * Set wrapper SDK information to use when building device properties.
 *
 * @param wrapperSdk wrapper SDK information.
 */
+ (void)setWrapperSdk:(SNMWrapperSdk *)wrapperSdk;

@end
