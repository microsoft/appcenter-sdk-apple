// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSHttpClientProtocol.h"

@interface MSHttpClient : NSObject <MSHttpClientProtocol>

/**
 * Creates an instance of MSHttpClient.
 *
 * @return A new instance of MSHttpClient.
 */
- (instancetype)init;

/**
 * Creates an instance of MSHttpClient with default retry logic.
 *
 * @param compressionEnabled Enable or disable payload compression.
 *
 * @return A new instance of MSHttpClient.
 */
- (instancetype)initWithCompressionEnabled:(BOOL)compressionEnabled;

/**
 * Creates an instance of MSHttpClient with no retry logic.
 *
 * @param compressionEnabled Enable or disable payload compression.
 *
 * @return A new instance of MSHttpClient.
 */
- (instancetype)initNoRetriesWithCompressionEnabled:(BOOL)compressionEnabled;

/**
 * Creates an instance of MSHttpClient.
 *
 * @param maxHttpConnectionsPerHost The maximum number of connections that can be open for a single host at once.
 * @param compressionEnabled Enable or disable payload compression.
 *
 * @return A new instance of MSHttpClient.
 */
- (instancetype)initWithMaxHttpConnectionsPerHost:(NSInteger)maxHttpConnectionsPerHost compressionEnabled:(BOOL)compressionEnabled;

@end
