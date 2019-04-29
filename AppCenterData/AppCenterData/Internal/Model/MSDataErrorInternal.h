// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataError.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDataError ()

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
