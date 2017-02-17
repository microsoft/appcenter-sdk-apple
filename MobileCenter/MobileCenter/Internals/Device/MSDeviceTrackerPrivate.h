#import "MSDevice.h"
#import "MSDeviceTracker.h"
#import "MSWrapperSdk.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>

@class MSDeviceHistoryInfo;

@interface MSDeviceTracker ()

/**
 * History of past devices.
 */
@property (nonatomic)NSMutableArray<MSDeviceHistoryInfo *> *pastDevices;

+ (BOOL)needsRefresh;

+ (void)setNeedsRefresh:(BOOL)needsRefresh;

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
+ (void)setWrapperSdk:(MSWrapperSdk *)wrapperSdk;


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
 * @param tOffset Offset that will be used to find a matching MSDevice in history.
 *
 * @return Instance of MSDevice that's closest to tOffset.
 *
 * @discussion If we cannot find a device that's within the range of the tOffset, the latest device from history will be
 * returned. If there is no history, we return the current MSDevice.
 */
- (MSDevice *)deviceForToffset:(NSNumber *)tOffset;

@end
