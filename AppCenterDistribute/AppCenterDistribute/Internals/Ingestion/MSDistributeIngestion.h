// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSHttpIngestion.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSHttpClientProtocol;

/**
 * The header name for update token.
 */
static NSString *const kMSHeaderUpdateApiToken = @"x-api-token";

@interface MSDistributeIngestion : MSHttpIngestion

/**
 * AppSecret for the application.
 */
@property(nonatomic) NSString *appSecret;

/**
 * Initialize the Ingestion.
 *
 * @param httpClient Http client.
 * @param baseUrl Base url.
 * @param appSecret A unique and secret key used to identify the application.
 *
 * @return An ingestion instance.
 */
- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient baseUrl:(nullable NSString *)baseUrl appSecret:(NSString *)appSecret;

/**
 * Check a new release from public update track.
 *
 * @param queryStrings An array of query strings.
 * @param completionHandler The completion handler block to be called after checking a new release.
 */
- (void)checkForPublicUpdateWithQueryStrings:(NSDictionary *)queryStrings completionHandler:(MSSendAsyncCompletionHandler)completionHandler;

/**
 * Check a new release from private update track.
 *
 * @param updateToken The update token stored in keychain. This parameter is optional and the update will be considered as public
 * distribution if it is nil.
 * @param queryStrings An array of query strings.
 * @param completionHandler The completion handler block to be called after checking a new release.
 */
- (void)checkForPrivateUpdateWithUpdateToken:(NSString *)updateToken
                                queryStrings:(NSDictionary *)queryStrings
                           completionHandler:(MSSendAsyncCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
