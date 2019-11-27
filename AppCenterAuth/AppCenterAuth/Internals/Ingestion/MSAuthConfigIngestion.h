// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAuthConfig.h"
#import "MSHttpIngestion.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAuthConfigIngestion : MSHttpIngestion

/**
 * AppSecret for the application.
 */
@property(nonatomic) NSString *appSecret;

/**
 * Initialize the Ingestion.
 *
 * @param httpClient The http client.
 * @param baseUrl Base url.
 * @param appSecret A unique and secret key used to identify the application.
 *
 * @return An ingestion instance.
 */
- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                 baseUrl:(nullable NSString *)baseUrl appSecret:(NSString *)appSecret;

@end

NS_ASSUME_NONNULL_END
