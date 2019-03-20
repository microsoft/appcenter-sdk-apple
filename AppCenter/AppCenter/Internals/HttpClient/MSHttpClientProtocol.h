// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

typedef void (^MSHttpRequestCompletionHandler)(NSHTTPURLResponse *response, NSData *data, NSError *error);

@protocol MSHttpClientProtocol <NSObject>

@required

/**
 * Send data to backend
 *
 * @param data A data instance that will be transformed request body.
 * @param headers HTTP headers.
 * @param url The endpoint to use in the HTTP request.
 * @param method The HTTP method (verb) to use for the HTTP request (e.g. GET, POST, etc.).
 * @param handler Completion handler.
 */
- (void)sendAsync:(nullable NSObject *)data
    headers:(nullable NSDictionary<NSString*, NSString*> *)headers
              url:(NSURL *)url
           method:(NSString *)method
    completionHandler:(MSHttpRequestCompletionHandler)handler;

@end