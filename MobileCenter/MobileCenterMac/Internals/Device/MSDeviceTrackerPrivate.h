#import <AppKit/AppKit.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <sys/sysctl.h>
#import "MSDevicePrivate.h"
#import "MSDeviceTracker.h"
#import "MSWrapperSdk.h"

// Key to device history.
static NSString *const kMSPastDevicesKey = @"pastDevicesKey";

@class MSDeviceHistoryInfo;

@interface MSDeviceTracker ()

/**
 * History of past devices.
 */
@property(nonatomic) NSMutableArray<MSDeviceHistoryInfo *> *deviceHistory;

/**
 * Sets a flag that will cause MSDeviceTracker to update it's device info the next time the device property is accessed.
 * Mostly intended for Unit Testing.
 */
+ (void)refreshDeviceNextTime;

/**
 * Clears the device history in memory and in NSUserDefaults as well as the current device.
 */
- (void)clearDevices;

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
 *  @return The OS name as an NSString.
 */
- (NSString *)osName;

/**
 *  Get the OS version.
 *
 *  @return The OS version as an NSString.
 */
- (NSString *)osVersion;

/**
 *  Get the device current locale.
 *
 *  @param deviceLocale Device current locale.
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
 *  Get the rendered screen size.
 *
 *  @return The size of the screen as an NSString with format "HEIGHTxWIDTH".
 */
- (NSString *)screenSize;

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
- (void)setWrapperSdk:(MSWrapperSdk *)wrapperSdk;

/**
 *  Return a new Instance of MSDevice.
 *
 * @returns A new Instance of MSDevice. @see MSDevice
 *
 * @discussion Intended to be used to update the device-property of MSDeviceTracker @see MSDeviceTracker.
 */
- (MSDevice *)updatedDevice;

/**
 * Return a device from the history of past devices. This will be used e.g. for Crashes after relaunch.
 *
 * @param toffset Offset that will be used to find a matching MSDevice in history.
 *
 * @return Instance of MSDevice that's closest to tOffset.
 *
 * @discussion If we cannot find a device that's within the range of the tOffset, the latest device from history will be
 * returned. If there is no history, we return the current MSDevice.
 */
- (MSDevice *)deviceForToffset:(NSNumber *)toffset;

@end
