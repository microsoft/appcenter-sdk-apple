/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * HttpSender configuration protocol to customize HTTP communication to backend.
 */
@protocol MSHttpSenderConfiguration <NSObject>

/**
 * Retry intervals used by calls in case of recoverable errors.
 *
 * @return A list of retry intervals.
 */
- (NSArray *)retryIntervals;

/**
 * An API path in the URL that is used to talk to HTTP endpoint.
 *
 * @return An API path string.
 */
- (NSString *)apiPath;

@end

NS_ASSUME_NONNULL_END
