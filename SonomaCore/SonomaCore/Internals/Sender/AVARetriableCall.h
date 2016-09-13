/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASender.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface AVARetriableCall : NSObject <AVASenderCall>

/**
 * A timer source which is used to flush the queue after a certain amount of time.
 */
@property(nonatomic, strong, nullable) dispatch_source_t timerSource;

/**
 *  Number of retries performed for this call.
 */
@property(nonatomic) NSUInteger retryCount;

/**
 *  Indicate if has reached the max retried.
 *
 *  @return YES if max retry has reached, NO otherwise.
 */
- (BOOL)hasReachedMaxRetries;

@end
NS_ASSUME_NONNULL_END
