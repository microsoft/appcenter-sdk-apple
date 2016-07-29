/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVALogContainer.h"
#import "AVA_Reachability.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^AVASendAsyncCompletionHandler)(NSString *batchId, NSError *error, NSUInteger statusCode);
@protocol AVASender <NSObject>
/**
 * Initialize the Sender
 *
 * @param url Base url
 * @param headers Http headers
 * @param queryStrings array of query strings
 * @param reachability network reachability helper
 */

- (id)initWithBaseUrl:(NSString *)baseUrl
              headers:(NSDictionary *)headers
         queryStrings:(NSDictionary *)queryStrings
         reachability:(AVA_Reachability *)reachability;

/**
 * Send logs in batch
 *
 * @param logContainer Batch of logs
 * @param queue Queue for dispatching the completion handler
 * @param handler Completion handler
 */

- (void)sendAsync:(nonnull AVALogContainer *)logs
    callbackQueue:(nullable dispatch_queue_t)callbackQueue
completionHandler:(nonnull AVASendAsyncCompletionHandler)handler;
@end
NS_ASSUME_NONNULL_END