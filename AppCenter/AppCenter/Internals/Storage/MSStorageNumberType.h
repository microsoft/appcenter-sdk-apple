// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSStorageBindableType.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSStorageNumberType : NSObject <MSStorageBindableType>

@property(nonatomic) NSNumber *value;

/**
 * Initializer with a value represented as NSNumber.
 */
- (instancetype)initWithValue:(NSNumber *)value;

@end

NS_ASSUME_NONNULL_END
