// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@protocol MSHttpClientProtocol;

@protocol MSHttpClientDelegate <NSObject>

@optional

/**
 * Triggered after the HTTP client has paused its state.
 *
 * @param httpClient The HTTP client.
 */
- (void)httpClientDidPause:(id<MSHttpClientProtocol>)httpClient;

/**
 * Triggered after the HTTP client has resumed its state.
 *
 * @param httpClient The HTTP client.
 */
- (void)httpClientDidResume:(id<MSHttpClientProtocol>)httpClient;

/**
 * Triggered when the client receives a fatal error.
 *
 * @param httpClient Http client.
 */
- (void)httpClientDidReceiveFatalError:(id<MSHttpClientProtocol>)httpClient;

@end
