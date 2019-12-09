// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSHttpClientProtocol.h"
#import "MSHttpIngestion.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAppCenterIngestion : MSHttpIngestion

/**
 * The app secret.
 */
@property(nonatomic, copy) NSString *appSecret;

/**
 * Initialize the Ingestion.
 *
 * @param baseUrl Base url.
 * @param installId A unique installation identifier.
 * @param httpClient The underlying HTTP client.
 *
 * @return An ingestion instance.
 */
- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient baseUrl:(NSString *)baseUrl installId:(NSString *)installId;

@end

NS_ASSUME_NONNULL_END
