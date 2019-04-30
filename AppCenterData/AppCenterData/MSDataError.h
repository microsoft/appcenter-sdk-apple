// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSDataError : NSError

/**
 * Get the inner error if exists.
 *
 * @return The inner error.
 */
- (NSError *)innerError;

@end

NS_ASSUME_NONNULL_END
