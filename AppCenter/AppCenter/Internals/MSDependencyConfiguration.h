// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@protocol MSHttpClientProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface MSDependencyConfiguration : NSObject

@property(class, nonatomic, nullable) id<MSHttpClientProtocol> httpClient;

@end

NS_ASSUME_NONNULL_END
