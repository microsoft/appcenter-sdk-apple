/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AVALogContainer.h"

typedef NS_ENUM(NSInteger, AVASendPriority) {
  AVASendPriorityDefault,
  AVASendPriorityLow,
  AVASendPriorityHight,
  AVASendPriorityBackground
};

typedef void (^SendAsyncCompletionHandler)(NSError* error);

@protocol AVASender <NSObject>

@required
/**
 * Initialize the Sender
 *
 * @param url Base url
 */
- (id)initWithBaseUrl:(NSString*)url;

/**
 * Send logs in batch
 *
 * @param logs Batched log
 * @param queue Queue for dispatching the completion handler
 * @param handler Completion handler
 */
-(NSNumber*)sendLogsAsync:(AVALogContainer*)logs
            callbackQueue:(dispatch_queue_t)callbackQueue
        completionHandler:(SendAsyncCompletionHandler)handler;

@end
