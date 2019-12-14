// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDependencyConfiguration.h"
#import "MSHttpClientProtocol.h"

static id<MSHttpClientProtocol> _httpClient;

@implementation MSDependencyConfiguration

+ (id<MSHttpClientProtocol>)httpClient {
  @synchronized(self) {
    return _httpClient;
  }
}

+ (void)setHttpClient:(nullable id<MSHttpClientProtocol>)httpClient {
  @synchronized(self) {
    _httpClient = httpClient;
  }
}

@end
