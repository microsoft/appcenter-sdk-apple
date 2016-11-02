/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSSenderCallDelegate.h"
#import "MSSenderUtils.h"
#import <Foundation/Foundation.h>

@protocol MSSender;

@protocol MSSenderCall <NSObject>

/**
 *  Call delegate.
 */
@property(nonatomic, weak) id<MSSenderCallDelegate> delegate;

/**
 *  Is call currently being processed.
 */
@property(nonatomic) BOOL isProcessing;

/**
 *  Log container.
 */
@property(nonatomic) MSLogContainer *logContainer;

/**
 *  Call completion handler used for communicating with calling component.
 */
@property(nonatomic) MSSendAsyncCompletionHandler completionHandler;

/**
 *  Call completed with error/success.
 *
 *  @param sender     sender object.
 *  @param statusCode status code.
 *  @param error      call error.
 */
- (void)sender:(id<MSSender>)sender callCompletedWithStatus:(NSUInteger)statusCode error:(NSError *)error;

@end
