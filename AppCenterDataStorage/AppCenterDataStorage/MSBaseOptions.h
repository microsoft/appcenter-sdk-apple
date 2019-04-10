// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSBaseOptions : NSObject

/**
 * Device document time-to-live in seconds. Default is one hour.
 */
@property NSTimeInterval deviceTimeToLive;

/**
 * Initialize a BaseOptions object.
 *
 * @param deviceTimeToLive Device document time to live in seconds.
 *
 * @return A BaseOptions instance.
 */
- (instancetype)initWithDeviceTimeToLive:(NSTimeInterval)deviceTimeToLive;

@end
