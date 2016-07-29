/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AVASender.h"

@interface AVASenderCall : NSObject

/**
 *  Is call currently being processed
 */
@property (nonatomic) BOOL isProcessing;

/**
 *  Log container
 */
@property (nonatomic) AVALogContainer *logContainer;

/**
 *  Callback queue
 */
@property (nonatomic) dispatch_queue_t callbackQueue;

/**
 *  Call completion handler used for communicating with calling component
 */
@property (nonatomic) AVASendAsyncCompletionHandler completionHandler;

/**
 *  Number of retries performed for this call
 */
@property (nonatomic) NSUInteger retryCount;

/**
 *  Indicate if has reached the max retried
 *
 *  @return YES if max retry has reached, NO otherwise
 */
- (BOOL)hasReachedMaxRetries;

@end
