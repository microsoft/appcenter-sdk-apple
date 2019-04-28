// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSDataError : NSObject

/**
 * Document error.
 */
@property(nonatomic, strong, readonly) NSError *error;

/**
 * Error code.
 */
@property(nonatomic, readonly) NSInteger errorCode;

/**
 * Extract an error code (HTTP) from any NSError instance.
 *
 * @param error An error object.
 *
 * @return The error code.
 */
+ (NSInteger)errorCodeFromError:(NSError *)error NS_SWIFT_NAME(errorCode(from:));

@end
