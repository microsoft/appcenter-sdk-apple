// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"

@interface MSCustomPropertiesLog : MSAbstractLog

/**
 * Key/value pair properties.
 */
@property(nonatomic) NSDictionary<NSString *, NSObject *> *properties;

@end
