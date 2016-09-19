/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 *
 * OpenAPI spec version: 1.0.0-preview20160708
 */

#import "SNMAbstractLog.h"
#import <Foundation/Foundation.h>

@interface SNMDevice : NSObject <SNMSerializableObject>

/*
 * Name of the SDK. Consists of the name of the SDK and the platform, e.g. "sonomasdk.ios", "sonomasdk.android"
 */
@property(nonatomic) NSString *sdkName;

/*
 * Version of the SDK in semver format, e.g. "1.2.0" or "0.12.3-alpha.1".
 */
@property(nonatomic) NSString *sdkVersion;

/*
 * Version of the wrapper SDK. When the SDK is embedding another base SDK (for example Xamarin.Android wraps Android),
 * the Xamarin specific version is populated into this field while sdkVersion refers to the original Android SDK.
 * [optional]
 */
@property(nonatomic) NSString *wrapperSdkVersion;

/*
 * Name of the wrapper SDK (examples: Xamarin, Cordova).  [optional]
 */
@property(nonatomic) NSString *wrapperSdkName;

/*
 * Device model (example: iPad2,3).
 */
@property(nonatomic) NSString *model;

/*
 * Device manufacturer (example: HTC).
 */
@property(nonatomic) NSString *oemName;

/*
 * OS name (example: iOS).
 */
@property(nonatomic) NSString *osName;

/*
 * OS version (example: 9.3.0).
 */
@property(nonatomic) NSString *osVersion;

/*
 * OS build code (example: LMY47X).  [optional]
 */
@property(nonatomic) NSString *osBuild;

/*
 * API level when applicable like in Android (example: 15).  [optional]
 */
@property(nonatomic) NSNumber *osApiLevel;

/*
 * Language code (example: en_US).
 */
@property(nonatomic) NSString *locale;

/*
 * The offset in minutes from UTC for the device time zone, including daylight savings time.
 */
@property(nonatomic) NSNumber *timeZoneOffset;

/*
 * Screen size of the device in pixels (example: 640x480).
 */
@property(nonatomic) NSString *screenSize;

/*
 * Application version name, e.g. 1.1.0
 */
@property(nonatomic) NSString *appVersion;

/*
 * Carrier name (for mobile devices).  [optional]
 */
@property(nonatomic) NSString *carrierName;

/*
 * Carrier country code (for mobile devices).  [optional]
 */
@property(nonatomic) NSString *carrierCountry;

/*
 * The app's build number, e.g. 42.
 */
@property(nonatomic) NSString *appBuild;

/*
 * The bundle identifier, package identifier, or namespace, depending on what the individual plattforms use,  .e.g
 * com.microsoft.example.  [optional]
 */
@property(nonatomic) NSString *appNamespace;

/*
 * Label that is used to identify application code 'version' released via Live Update beacon running on device
 */
@property(nonatomic) NSString *liveUpdateReleaseLabel;

/*
 * Identifier of environment that current application release belongs to, deployment key then maps to environment like Production, Staging.
 */
@property(nonatomic) NSString *liveUpdateDeploymentKey;

/*
 * Hash of all files (ReactNative or Cordova) deployed to device via LiveUpdate beacon.
 * Helps identify the Release version on device or need to download updates in future
 */
@property(nonatomic) NSString *liveUpdatePackageHash;

/**
 * Is equal to another device log
 *
 * @param device Device log
 *
 * @return Return YES if equsl and NO if not equal
 */
- (BOOL)isEqual:(SNMDevice *)device;

@end
