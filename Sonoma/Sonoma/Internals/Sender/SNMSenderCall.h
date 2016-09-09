/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMSenderCallDelegate.h"
#import "SNMSenderUtils.h"
#import <Foundation/Foundation.h>

@protocol SNMSenderCall <NSObject>

/**
 *  Call delegate.
 */
@property(nonatomic, weak) id<SNMSenderCallDelegate> delegate;

/**
 *  Is call currently being processed.
 */
@property(nonatomic) BOOL isProcessing;

/**
 *  Log container.
 */
@property(nonatomic) SNMLogContainer *logContainer;

/**
 *  Callback queue.
 */
@property(nonatomic) dispatch_queue_t callbackQueue;

/**
 *  Call completion handler used for communicating with calling component.
 */
@property(nonatomic) SNMSendAsyncCompletionHandler completionHandler;

/**
 *  Call completed with error/success.
 *
 *  @param sender     sender object.
 *  @param error      call error.
 *  @param statusCode status code.
 */
- (void)sender:(id<SNMSenderCallDelegate>)sender callCompletedWithError:(NSError *)error status:(NSUInteger)statusCode;

@end
