// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataError.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDataError ()

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
 * Create a MSDataError object.
 *
 * @param userInfo Contains context about the actual error.
 * @param code Error code.
 *
 * @return Instance of error object.
 */
- (instancetype)initWithUserInfo:(NSDictionary *)userInfo code:(NSInteger)code;

@end

NS_ASSUME_NONNULL_END
