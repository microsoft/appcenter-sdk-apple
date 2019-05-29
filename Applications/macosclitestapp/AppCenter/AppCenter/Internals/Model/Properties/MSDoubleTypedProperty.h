// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSTypedProperty.h"

static NSString *const kMSDoubleTypedPropertyType = @"double";

@interface MSDoubleTypedProperty : MSTypedProperty

/**
 * Double property value.
 */
@property(nonatomic) double value;

@end
