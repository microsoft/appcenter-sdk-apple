// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSStorageBindableType.h"

@interface MSStorageTextType : NSObject <MSStorageBindableType>

@property(nonatomic, nullable) NSString *value;

/**
 * Initializer with a value represented as NSString.
 */
- (instancetype __nonnull)initWithValue:(nullable NSString *)value;

@end
