/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMSender.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface SNMRetriableCall : NSObject <SNMSenderCall>

/**
 * A timer source which is used to flush the queue after a certain amount of time.
 */
@property(nonatomic, strong, nullable) dispatch_source_t timerSource;

/**
 * Number of retries performed for this call.
 */
@property(nonatomic) NSUInteger retryCount;

/**
 * Initialize a call with specified retry intervals.
 *
 * @param retryIntervals Retry intervals used in case of recoverable errors.
 *
 * @return A retriable call instance.
 */
- (id)initWithRetryIntervals:(NSArray *)retryIntervals;

/**
 * Indicate if the limit of maximum retries has been reached.
 *
 * @return YES if the limit of maximum retries has been reached, NO otherwise.
 */
- (BOOL)hasReachedMaxRetries;

@end
NS_ASSUME_NONNULL_END
