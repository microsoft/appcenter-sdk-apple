// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSHttpClient;

NS_ASSUME_NONNULL_BEGIN

@interface MSDependencyConfiguration : NSObject

/**
 * Gets the http client.
 *
 * @return The http client.
 */
+ (MSHttpClient *)getHttpClient;

/**
 * Sets the http client.
 *
 * @param httpClient The http client.
 */
+ (void)setHttpClient:(MSHttpClient *)httpClient;

@end

NS_ASSUME_NONNULL_END
