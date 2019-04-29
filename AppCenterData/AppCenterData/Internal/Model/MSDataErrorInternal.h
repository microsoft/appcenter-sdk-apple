// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataError.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDataError ()

/**
 * Create an instance with error object.
 *
 * @param error An error object.
 *
 * @return A new `MSDataError` instance.
 */
- (instancetype)initWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
