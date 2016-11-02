/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAbstractLog.h"
#import <Foundation/Foundation.h>

@interface MSDevice () <MSSerializableObject>

/*
 * Name of the SDK. Consists of the name of the SDK and the platform, e.g. "sonoma.ios", "sonoma.android"
 */
@property(nonatomic, readwrite) NSString *sdkName;

/*
 * Version of the SDK in semver format, e.g. "1.2.0" or "0.12.3-alpha.1".
 */
@property(nonatomic, readwrite) NSString *sdkVersion;

/*
 * Device model (example: iPad2,3).
 */
@property(nonatomic, readwrite) NSString *model;

/*
 * Device manufacturer (example: HTC).
 */
@property(nonatomic, readwrite) NSString *oemName;

/*
 * OS name (example: iOS).
 */
@property(nonatomic, readwrite) NSString *osName;

/*
 * OS version (example: 9.3.0).
 */
@property(nonatomic, readwrite) NSString *osVersion;

/*
 * OS build code (example: LMY47X).  [optional]
 */
@property(nonatomic, readwrite) NSString *osBuild;

/*
 * API level when applicable like in Android (example: 15).  [optional]
 */
@property(nonatomic, readwrite) NSNumber *osApiLevel;

/*
 * Language code (example: en_US).
 */
@property(nonatomic, readwrite) NSString *locale;

/*
 * The offset in minutes from UTC for the device time zone, including daylight savings time.
 */
@property(nonatomic, readwrite) NSNumber *timeZoneOffset;

/*
 * Screen size of the device in pixels (example: 640x480).
 */
@property(nonatomic, readwrite) NSString *screenSize;

/*
 * Application version name, e.g. 1.1.0
 */
@property(nonatomic, readwrite) NSString *appVersion;

/*
 * Carrier name (for mobile devices).  [optional]
 */
@property(nonatomic, readwrite) NSString *carrierName;

/*
 * Carrier country code (for mobile devices).  [optional]
 */
@property(nonatomic, readwrite) NSString *carrierCountry;

/*
 * The app's build number, e.g. 42.
 */
@property(nonatomic, readwrite) NSString *appBuild;

/*
 * The bundle identifier, package identifier, or namespace, depending on what the individual plattforms use,  .e.g
 * com.microsoft.example.  [optional]
 */
@property(nonatomic, readwrite) NSString *appNamespace;


@end
