/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMDevice.h"

/**
 * Provide and keep track of device log based on collected properties.
 */
@interface SNMDeviceTracker : NSObject

/**
 * Current device log.
 */
@property(nonatomic, readonly) SNMDevice *device;

@end
