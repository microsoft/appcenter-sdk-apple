// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSTokenExchange.h"
#import "MSTokenResult.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSTokenExchange ()

// WIP
+ (MSTokenResult *_Nullable)retrieveCachedToken:(NSString *)partitionName;

@end

NS_ASSUME_NONNULL_END
