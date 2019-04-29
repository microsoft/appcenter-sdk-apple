// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSDataError : NSError

/**
 * Create a MSDataError object.
 *
 * @param innerError Inner error that provides more context about the actual error.
 * @param code Error code.
 * @param message Error message.
 *
 * @return Instance of error object.
 */
- (instancetype)initWithInnerError:(NSError *_Nullable)innerError code:(NSInteger)code message:(NSString *_Nullable)message;

/**
 * Get the inner error if exists.
 *
 * @return The inner error.
 */
- (NSError *)innerError;

@end

NS_ASSUME_NONNULL_END
