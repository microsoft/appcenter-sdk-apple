/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAConstants+Internal.h"
#import "AVALogContainer.h"
#import <Foundation/Foundation.h>

typedef void (^AVASendAsyncCompletionHandler)(NSError *error,
                                              NSUInteger statusCode,
                                              NSString *batchId);
@protocol AVASender <NSObject>

@required
/**
 * Initialize the Sender
 *
 * @param url Base url
 */
- (id)initWithBaseUrl:(NSString *)url;

/**
 * Send logs in batch
 *
 * @param logs Batched log
 * @param queue Queue for dispatching the completion handler
 * @param priority Send priority
 * @param handler Completion handler
 */
- (NSNumber *)sendAsync:(AVALogContainer *)logs
              callbackQueue:(dispatch_queue_t)callbackQueue
                   priority:(float)priority
          completionHandler:(AVASendAsyncCompletionHandler)handler;

- (NSNumber *)sendAsync:(AVALogContainer *)logs
      completionHandler:(AVASendAsyncCompletionHandler)handler;

@end
