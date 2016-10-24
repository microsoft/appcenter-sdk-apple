/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMAbstractLog.h"
#import <Foundation/Foundation.h>

@interface SNMWrapperSdk () <SNMSerializableObject>

/*
 * Version of the wrapper SDK. When the SDK is embedding another base SDK (for example Xamarin.Android wraps Android),
 * the Xamarin specific version is populated into this field while sdkVersion refers to the original Android SDK.
 * [optional]
 */
@property(nonatomic, readwrite) NSString *wrapperSdkVersion;

/*
 * Name of the wrapper SDK (examples: Xamarin, Cordova).  [optional]
 */
@property(nonatomic, readwrite) NSString *wrapperSdkName;

/*
 * Label that is used to identify application code 'version' released via Live Update beacon running on device
 */
@property(nonatomic, readwrite) NSString *liveUpdateReleaseLabel;

/*
 * Identifier of environment that current application release belongs to, deployment key then maps to environment like Production, Staging.
 */
@property(nonatomic, readwrite) NSString *liveUpdateDeploymentKey;

/*
 * Hash of all files (ReactNative or Cordova) deployed to device via LiveUpdate beacon.
 * Helps identify the Release version on device or need to download updates in future
 */
@property(nonatomic, readwrite) NSString *liveUpdatePackageHash;

@end
