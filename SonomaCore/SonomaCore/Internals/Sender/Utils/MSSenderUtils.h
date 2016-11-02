/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

typedef void (^SNMSendAsyncCompletionHandler)(NSString *batchId, NSError *error, NSUInteger statusCode);

@interface MSSenderUtils : NSObject

/**
 *  Indicate if the http response is recoverable.
 *
 *  @param statusCode Http status code.
 *
 *  @return is recoverable.
 */
+ (BOOL)isRecoverableError:(NSInteger)statusCode;

/**
 *  Get http status code from response.
 *
 *  @param response http response.
 *
 *  @return status code.
 */
+ (NSInteger)getStatusCode:(NSURLResponse *)response;

/**
 *  Indicate if error is due to no internet connection.
 *
 *  @param error http error.
 *
 *  @return is no network connection error.
 */
+ (BOOL)isNoInternetConnectionError:(NSError *)error;

/**
 *  Indicate if error is due to cancelation of the request.
 *
 *  @param error http error.
 *
 *  @return is request canceled.
 */
+ (BOOL)isRequestCanceledError:(NSError *)error;

@end
