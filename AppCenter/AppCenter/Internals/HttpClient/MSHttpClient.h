// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSHttpClientProtocol.h"

#define DEFAULT_RETRY_INTERVALS @[ @10, @(5 * 60), @(20 * 60) ]

@interface MSHttpClient : NSObject <MSHttpClientProtocol>

/**
 * Creates an instance of MSHttpClient.
 *
 * @return A new instance of MSHttpClient.
 */
- (instancetype)init;

/**
 * Creates an instance of MSHttpClient.
 *
 * @param maxHttpConnectionsPerHost The maximum number of connections that can be open for a single host at once.
 *
 * @return A new instance of MSHttpClient.
 */
- (instancetype)initWithMaxHttpConnectionsPerHost:(NSInteger)maxHttpConnectionsPerHost;

@end
