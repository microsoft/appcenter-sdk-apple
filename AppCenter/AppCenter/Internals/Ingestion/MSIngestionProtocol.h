// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSEnable.h"
#import "MSHttpClientProtocol.h"
#import "MSHttpUtil.h"
#import "MS_Reachability.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSIngestionDelegate;

typedef void (^MSSendAsyncCompletionHandler)(NSString *callId, NSHTTPURLResponse *_Nullable response, NSData *_Nullable data,
                                             NSError *_Nullable error);

@protocol MSIngestionProtocol <NSObject, MSEnable>

/**
 * The indicator of readiness to send data.
 */
@property(nonatomic, readonly, getter=isReadyToSend) BOOL readyToSend;

/**
 * Send data.
 *
 * @param data Instance that will be transformed to request body.
 * @param handler Completion handler.
 */
- (void)sendAsync:(nullable NSObject *)data completionHandler:(MSSendAsyncCompletionHandler)handler;

/**
 * Send data.
 *
 * @param data Instance that will be transformed to request body.
 * @param eTag HTTP entity tag.
 * @param handler Completion handler.
 */
- (void)sendAsync:(nullable NSObject *)data eTag:(nullable NSString *)eTag completionHandler:(MSSendAsyncCompletionHandler)handler;

@end

NS_ASSUME_NONNULL_END
