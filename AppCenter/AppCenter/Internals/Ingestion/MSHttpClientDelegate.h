// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@protocol MSHttpClientDelegate <NSObject>

@optional

/**
 * A method is called right before sending HTTP request.
 *
 * @param url A URL.
 * @param headers A collection of headers.
 */
- (void)willSendHTTPRequestToURL:(NSURL *)url withHeaders:(NSDictionary<NSString *, NSString *> *)headers;

@end
