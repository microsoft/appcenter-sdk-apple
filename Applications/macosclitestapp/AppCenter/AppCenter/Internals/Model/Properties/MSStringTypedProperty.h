// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSTypedProperty.h"

static NSString *const kMSStringTypedPropertyType = @"string";

@interface MSStringTypedProperty : MSTypedProperty

/**
 * String property value.
 */
@property(nonatomic, copy) NSString *value;

@end
