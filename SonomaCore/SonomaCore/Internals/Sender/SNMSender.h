/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */
#import "SNMLogContainer.h"
#import "SNMSenderCall.h"
#import "SNMSenderCallDelegate.h"
#import "SNMSenderUtils.h"
#import "SNM_Reachability.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SNMSender <NSObject, SNMSenderCallDelegate>
/**
 * Initialize the Sender.
 *
 * @param url Base url.
 * @param headers Http headers.
 * @param queryStrings array of query strings.
 * @param reachability network reachability helper.
 */

- (id)initWithBaseUrl:(NSString *)baseUrl
              headers:(NSDictionary *)headers
         queryStrings:(NSDictionary *)queryStrings
         reachability:(SNM_Reachability *)reachability;

/**
 * Send logs in batch.
 *
 * @param logContainer Batch of logs.
 * @param queue Queue for dispatching the completion handler.
 * @param handler Completion handler.
 */

- (void)sendAsync:(nonnull SNMLogContainer *)logs
    callbackQueue:(nullable dispatch_queue_t)callbackQueue
completionHandler:(nonnull SNMSendAsyncCompletionHandler)handler;

@end
NS_ASSUME_NONNULL_END
