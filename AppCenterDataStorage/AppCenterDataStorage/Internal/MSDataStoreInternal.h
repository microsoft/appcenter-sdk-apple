// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDataStore.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSHttpClientProtocol;

@interface MSDataStore <T : id <MSSerializableDocument>>() <MSServiceInternal>

/**
 * A token exchange url that is used to get resource tokens.
 */
@property(nonatomic, copy) NSURL *tokenExchangeUrl;

/**
 * HTTP client.
 */
@property(nonatomic, nullable) id<MSHttpClientProtocol> httpClient;

@end

NS_ASSUME_NONNULL_END
