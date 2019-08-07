// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSBaseOptions : NSObject

/**
 * Device document time-to-live in seconds.
 */
@property(assign) NSInteger deviceTimeToLive;

/**
 * Initialize a BaseOptions object with the default value.
 *
 * @return A BaseOptions instance.
 */
- (instancetype)init;

/**
 * Initialize a BaseOptions object.
 *
 * @param deviceTimeToLive Device document time to live in seconds.
 *
 * @return A BaseOptions instance.
 */
- (instancetype)initWithDeviceTimeToLive:(NSInteger)deviceTimeToLive;

@end
