// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSIngestionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

// HTTP request/response headers for eTag.
static NSString *const kMSETagResponseHeader = @"etag";
static NSString *const kMSETagRequestHeader = @"If-None-Match";

@interface MSHttpIngestion : NSObject <MSIngestionProtocol>

/**
 * Base URL (schema + authority + port only) used to communicate with the server.
 */
@property(nonatomic, copy) NSString *baseURL;

/**
 * API URL path used to identify an API from the server.
 */
@property(nonatomic, copy) NSString *apiPath;

/**
 * Send Url.
 */
@property(nonatomic) NSURL *sendURL;

/**
 * Request header parameters.
 */
@property(nonatomic) NSDictionary *httpHeaders;

/**
 * The HTTP Client.
 */
@property (nonatomic) id<MSHttpClientProtocol> httpClient;


/**
 * Send data to backend
 *
 * @param data A data instance that will be transformed request body.
 * @param eTag HTTP entity tag.
 * @param authToken Auth token to send data with.
 * @param handler Completion handler.
 */
- (void)sendAsync:(nullable NSObject *)data
                 eTag:(nullable NSString *)eTag
            authToken:(nullable NSString *)authToken
    completionHandler:(MSSendAsyncCompletionHandler)handler;

/**
 * Create a request based on data. Must override this method in sub classes.
 *
 * @param data A data instance that will be transformed to request body.
 * @param eTag HTTP entity tag.
 * @param authToken auth token to send data with.
 *
 * @return A URL request.
 */
- (NSURLRequest *)createRequest:(NSObject *)data eTag:(nullable NSString *)eTag authToken:(nullable NSString *)authToken;

/**
 * Get eTag from the given response.
 *
 * @param response HTTP response with eTag header.
 *
 * @return An eTag or `nil` if not found.
 */
+ (nullable NSString *)eTagFromResponse:(NSHTTPURLResponse *)response;

@end

NS_ASSUME_NONNULL_END
