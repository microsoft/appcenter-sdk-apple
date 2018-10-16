#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSDevice.h"

@interface MSDevice () <MSSerializableObject>

/*
 * Name of the SDK. Consists of the name of the SDK and the platform, e.g. "appcenter.ios", "appcenter.android"
 */
@property(nonatomic, copy) NSString *sdkName;

/*
 * Version of the SDK in semver format, e.g. "1.2.0" or "0.12.3-alpha.1".
 */
@property(nonatomic, copy) NSString *sdkVersion;

/*
 * Device model (example: iPad2,3).
 */
@property(nonatomic, copy) NSString *model;

/*
 * Device manufacturer (example: HTC).
 */
@property(nonatomic, copy) NSString *oemName;

/*
 * OS name (example: iOS).
 */
@property(nonatomic, copy) NSString *osName;

/*
 * OS version (example: 9.3.0).
 */
@property(nonatomic, copy) NSString *osVersion;

/*
 * OS build code (example: LMY47X). [optional]
 */
@property(nonatomic, copy) NSString *osBuild;

/*
 * API level when applicable like in Android (example: 15). [optional]
 */
@property(nonatomic, copy) NSNumber *osApiLevel;

/*
 * Language code (example: en_US).
 */
@property(nonatomic, copy) NSString *locale;

/*
 * The offset in minutes from UTC for the device time zone, including daylight savings time.
 */
@property(nonatomic) NSNumber *timeZoneOffset;

/*
 * Screen size of the device in pixels (example: 640x480).
 */
@property(nonatomic, copy) NSString *screenSize;

/*
 * Application version name, e.g. 1.1.0
 */
@property(nonatomic, copy) NSString *appVersion;

/*
 * Carrier name (for mobile devices). [optional]
 */
@property(nonatomic, copy) NSString *carrierName;

/*
 * Carrier country code (for mobile devices). [optional]
 */
@property(nonatomic, copy) NSString *carrierCountry;

/*
 * The app's build number, e.g. 42.
 */
@property(nonatomic, copy) NSString *appBuild;

/*
 * The bundle identifier, package identifier, or namespace, depending on what the individual plattforms use, .e.g com.microsoft.example.
 * [optional]
 */
@property(nonatomic, copy) NSString *appNamespace;

@end
