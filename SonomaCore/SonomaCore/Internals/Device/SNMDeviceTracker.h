/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMDevice.h"
#import "SNMWrapperSdk.h"

/**
 * Provide and keep track of device log based on collected properties.
 */
@interface SNMDeviceTracker : NSObject

/**
 * Current device log.
 */
@property(nonatomic, readonly) SNMDevice *device;

/**
 * Set wrapper SDK information to use when building device properties.
 *
 * @param wrapperSdk wrapper SDK information.
 */
+ (void)setWrapperSdk:(SNMWrapperSdk *)wrapperSdk;

/**
 * Refresh properties.
 */
- (void)refresh;

@end
