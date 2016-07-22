/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVADeviceLog.h"

/**
 *  Provide and keep track of device log based on collected characteristics.
 */
@interface AVADeviceTracker : NSObject

/**
 *  Current device log.
 */
@property(nonatomic, readonly) AVADeviceLog *device;

/**
 *  Refresh characteristics.
 */
- (void)refresh;

@end
