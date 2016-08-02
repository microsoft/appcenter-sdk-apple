/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASenderCallDelegate.h"
#import "AVASenderUtils.h"
#import <Foundation/Foundation.h>

@protocol AVASenderCall <NSObject>

/**
 *  Call delegate.
 */
@property(nonatomic) id<AVASenderCallDelegate> delegate;

/**
 *  Is call currently being processed.
 */
@property(nonatomic) BOOL isProcessing;

/**
 *  Log container.
 */
@property(nonatomic) AVALogContainer *logContainer;

/**
 *  Callback queue.
 */
@property(nonatomic) dispatch_queue_t callbackQueue;

/**
 *  Call completion handler used for communicating with calling component.
 */
@property(nonatomic) AVASendAsyncCompletionHandler completionHandler;

/**
 *  Call completed with error/success.
 *
 *  @param sender     sender object.
 *  @param error      call error.
 *  @param statusCode status code.
 */
- (void)sender:(id<AVASenderCallDelegate>)sender callCompletedWithError:(NSError *)error status:(NSUInteger)statusCode;

@end
