// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDependencyConfiguration.h"
#import "MSHttpClient.h"

static MSHttpClient *httpClientBacking;
static NSObject *lock;

@implementation MSDependencyConfiguration

+ (MSHttpClient *)getHttpClient {
  @synchronized(lock) {
    return httpClientBacking;
  }
}

+ (void)setHttpClient:(MSHttpClient *)httpClient {
  @synchronized(lock) {
    httpClientBacking = httpClient;
  }
}

@end
