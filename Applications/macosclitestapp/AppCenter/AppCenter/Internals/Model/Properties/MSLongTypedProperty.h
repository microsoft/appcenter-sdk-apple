// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSTypedProperty.h"

static NSString *const kMSLongTypedPropertyType = @"long";

@interface MSLongTypedProperty : MSTypedProperty

/**
 * Long property value (64-bit signed integer).
 */
@property(nonatomic) int64_t value;

@end
