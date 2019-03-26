// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpClientProtocol.h"
#import <Foundation/Foundation.h>

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
- (instancetype)initWithMaxHttpConnectionsPerHost:(int)maxHttpConnectionsPerHost;

/**
 * Enables or disables the client. All pending requests are canceled and discarded upon disabling.
 *
 * @param isEnabled The desired enabled state of the client - pass `YES` to enable, `NO` to disable.
 */
- (void)setEnabled:(BOOL)isEnabled;

@end
