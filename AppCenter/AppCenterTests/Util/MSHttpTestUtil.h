// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSHttpTestUtil : NSObject

+ (void)stubHttp500Response;

+ (void)stubHttp404Response;

+ (void)stubHttp200Response;

+ (void)stubNetworkDownResponse;

+ (void)stubLongTimeOutResponse;

+ (void)removeAllStubs;

+ (NSHTTPURLResponse *)createMockResponseForStatusCode:(int)statusCode headers:(NSDictionary *)headers;

@end
