// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

static NSString *const kMSTimezone = @"tz";

/**
 * Describes the location from which the event was logged.
 */
@interface MSLocExtension : NSObject <MSSerializableObject, MSModel>

/**
 * Time zone on the device.
 */
@property(nonatomic, copy) NSString *tz;

@end
