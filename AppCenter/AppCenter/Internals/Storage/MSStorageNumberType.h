// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSStorageBindableType.h"

@interface MSStorageNumberType : NSObject <MSStorageBindableType>

@property(nonatomic) NSNumber *value;

/**
 * Initializer with a value represented as NSNumber.
 */
- (instancetype)initWithValue:(NSNumber *)value;

@end
