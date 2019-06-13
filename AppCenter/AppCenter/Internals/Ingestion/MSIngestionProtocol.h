// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSEnable.h"
#import "MSHttpUtil.h"
#import "MSIngestionCallDelegate.h"
#import "MS_Reachability.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^MSSendAsyncCompletionHandler)(NSString *callId, NSHTTPURLResponse *_Nullable response, NSData *_Nullable data,
                                             NSError *_Nullable error);

@protocol MSIngestionDelegate;

@protocol MSIngestionProtocol <NSObject, MSIngestionCallDelegate, MSEnable>

/**
 * Reachability library.
 */
@property(nonatomic) MS_Reachability *reachability;

/**
 * A boolean value set to YES if the ingestion is paused or NO otherwise.
 */
@property(nonatomic, getter=isPaused) BOOL paused;

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
 * Add the given delegate to the ingestion.
 *
 * @param delegate Ingestion's delegate.
 */
- (void)addDelegate:(id<MSIngestionDelegate>)delegate;

/**
 * Delete the given delegate from the ingestion.
 *
 * @param delegate Ingestion's delegate.
 */
- (void)removeDelegate:(id<MSIngestionDelegate>)delegate;

/**
 * Pause the ingestion.
 * An ingestion is paused when it becomes disabled or on network issues. A paused state doesn't impact the current enabled state.
 *
 * @see resume.
 */
- (void)pause;

/**
 * Resume the ingestion.
 *
 * @see pause.
 */
- (void)resume;

@end

NS_ASSUME_NONNULL_END
