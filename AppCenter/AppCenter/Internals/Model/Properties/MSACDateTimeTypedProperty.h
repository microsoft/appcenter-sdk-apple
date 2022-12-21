// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACTypedProperty.h"

static NSString *const kMSACDateTimeTypedPropertyType = @"dateTime";

@interface MSACDateTimeTypedProperty : MSACTypedProperty<NSSecureCoding>

/**
 * Date and time property value.
 */
@property(nonatomic) NSDate *value;

@end
