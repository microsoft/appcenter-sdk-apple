// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSDataSourceError : NSObject

/**
 * Document error.
 */
@property(nonatomic, strong, readonly) NSError *error;

/**
 * Error code.
 */
@property(nonatomic, readonly) NSInteger errorCode;

/**
 * Create an instance with error object.
 *
 * @param error An error object.
 *
 * @return A new `MSDataSourceError` instance.
 */
- (instancetype)initWithError:(NSError *)error;

/**
 * Extract an error code (HTTP) from any NSError instance.
 *
 * @param error An error object.
 *
 * @return The error code.
 */
+ (NSInteger)errorCodeFromError:(NSError *)error;

@end