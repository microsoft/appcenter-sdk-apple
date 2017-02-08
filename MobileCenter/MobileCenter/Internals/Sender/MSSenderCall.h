/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSSenderCallDelegate.h"
#import "MSSenderUtil.h"

@import Foundation;

@protocol MSSender;

@protocol MSSenderCall <NSObject>

/**
 *  Call delegate.
 */
@property(nonatomic, weak) id <MSSenderCallDelegate> delegate;

/**
 *  Whether the request to send data has been submitted or not.
 */
@property(nonatomic) BOOL submitted;

/**
 *  Log container.
 */
@property(nonatomic) MSLogContainer *logContainer;

/**
 *  Call completion handler used for communicating with calling component.
 */
@property(nonatomic) MSSendAsyncCompletionHandler completionHandler;

/**
 * Reset and stop retrying.
 */
- (void)resetRetry;

/**
 *  Call completed with error/success.
 *
 *  @param sender     sender object.
 *  @param statusCode status code.
 *  @param error      call error.
 */
- (void)sender:(id <MSSender>)sender callCompletedWithStatus:(NSUInteger)statusCode error:(NSError *)error;

@end
