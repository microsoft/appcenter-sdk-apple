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
 * @param authToken Auth token to send data with.
 * @param handler Completion handler.
 */
- (void)sendAsync:(nullable NSObject *)data
            authToken:(nullable NSString *)__unused authToken
    completionHandler:(MSSendAsyncCompletionHandler)handler;

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
 * @param authToken Auth token to send data with.
 * @param handler Completion handler.
 */
- (void)sendAsync:(nullable NSObject *)data
                 eTag:(nullable NSString *)eTag
            authToken:(nullable NSString *)authToken
    completionHandler:(MSSendAsyncCompletionHandler)handler;

/**
 * Send data.
 *
 * @param data Instance that will be transformed to request body.
 * @param eTag HTTP entity tag.
 * @param handler Completion handler.
 */
- (void)sendAsync:(nullable NSObject *)data eTag:(nullable NSString *)eTag completionHandler:(MSSendAsyncCompletionHandler)handler;

/**
 * Pause ingestion.
 * The client is automatically paused when it becomes disabled or on network issues. A paused state doesn't impact the current enabled
 * state.
 *
 * @see resume.
 */
- (void)pause;

/**
 * Resume ingestion.
 *
 * @see pause.
 */
- (void)resume;

/**
 * Add a delegate.
 *
 * @param delegate The delegate being added.
 */
- (void)addDelegate:(id<MSIngestionDelegate>)delegate;

/**
 * Remove a delegate.
 *
 * @param delegate The delegate being removed.
 */
- (void)removeDelegate:(id<MSIngestionDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
