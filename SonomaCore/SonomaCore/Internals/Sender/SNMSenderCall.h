/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMSenderCallDelegate.h"
#import "SNMSenderUtils.h"
#import <Foundation/Foundation.h>

@protocol SNMSender;

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
 *  Call completion handler used for communicating with calling component.
 */
@property(nonatomic) SNMSendAsyncCompletionHandler completionHandler;

/**
 *  Call completed with error/success.
 *
 *  @param sender     sender object.
 *  @param statusCode status code.
 *  @param error      call error.
 */
- (void)sender:(id<SNMSender>)sender callCompletedWithStatus:(NSUInteger)statusCode error:(NSError *)error;

@end
