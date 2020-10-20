// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACWrapperSdkInternal.h"
#import <Foundation/Foundation.h>

@class MSACDevice;

/**
 * Provide and keep track of device log based on collected properties.
 */
@interface MSACDeviceTracker : NSObject

/**
 * Current device log. This will be updated on app launch.
 */
@property(nonatomic, readonly) MSACDevice *device;

/**
 * Returns singleton instance of MSACDeviceTracker.
 *
 * @return an instance of MSACDeviceTracker.
 */
+ (instancetype)sharedInstance;

/**
 * Clears the device history in memory and in NSUserDefaults keeping the current device.
 */
- (void)clearDevices;

/**
 * Get country code.
 *
 * @return country code.
 */
- (NSString *)getCountryCode;

/**
 * Get wrapper SDK.
 *
 * @return wrapper sdk.
 */
- (MSACWrapperSdk *)getWrapperSdk;

@end
