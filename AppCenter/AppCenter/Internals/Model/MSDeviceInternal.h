// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef MS_DEVICE_INTERNAL_H
#define MS_DEVICE_INTERNAL_H

#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSDevice.h"

static NSString *const kMSSDKName = @"sdkName";
static NSString *const kMSSDKVersion = @"sdkVersion";
static NSString *const kMSModel = @"model";
static NSString *const kMSOEMName = @"oemName";
static NSString *const kMSACOSName = @"osName";
static NSString *const kMSOSVersion = @"osVersion";
static NSString *const kMSOSBuild = @"osBuild";
static NSString *const kMSOSAPILevel = @"osApiLevel";
static NSString *const kMSLocale = @"locale";
static NSString *const kMSTimeZoneOffset = @"timeZoneOffset";
static NSString *const kMSScreenSize = @"screenSize";
static NSString *const kMSAppVersion = @"appVersion";
static NSString *const kMSCarrierName = @"carrierName";
static NSString *const kMSCarrierCountry = @"carrierCountry";
static NSString *const kMSAppBuild = @"appBuild";
static NSString *const kMSAppNamespace = @"appNamespace";

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

#endif
