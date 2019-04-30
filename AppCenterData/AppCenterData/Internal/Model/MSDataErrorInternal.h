// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataError.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDataError ()

/**
 * Create a MSDataError object.
 *
 * @param errorCode Error code.
 * @param innerError Inner error that provides more context about the actual error.
 * @param message Error message.
 *
 * @return Instance of error object.
 */
- (instancetype)initWithErrorCode:(NSInteger)errorCode innerError:(NSError *_Nullable)innerError message:(NSString *_Nullable)message;

/**
 * Create a MSDataError object.
 *
 * @param errorCode Error code.
 * @param userInfo Contains context about the actual error.
 *
 * @return Instance of error object.
 */
- (instancetype)initWithErrorCode:(NSInteger)errorCode userInfo:(NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
