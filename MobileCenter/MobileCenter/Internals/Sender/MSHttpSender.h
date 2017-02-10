/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSSender.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSHttpSender : NSObject <MSSender>

/**
 *	Send Url.
 */
@property(nonatomic, strong, readonly) NSURL *sendURL;

/**
 *	Request header parameters.
 */
@property(nonatomic, strong) NSDictionary *httpHeaders;

/**
 *  Pending http calls.
 */
@property(atomic, strong) NSMutableDictionary<NSString *, MSSenderCall *> *pendingCalls;

// TODO (jaelim): Add doc here.
- (void)sendAsync:(NSObject *)container
               callId:(NSString *)callId
    completionHandler:(MSSendAsyncCompletionHandler)handler;

@end

NS_ASSUME_NONNULL_END
