// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#define MS_DISPATCH_SELECTOR(declaration, object, selectorName, ...)                                                                       \
  ({                                                                                                                                       \
    (declaration [object methodForSelector:NSSelectorFromString(selectorName)])(object, NSSelectorFromString(selectorName),                \
                                                                                ##__VA_ARGS__);                                            \
  })

@interface MSDispatcherUtil : NSObject

+ (void)performBlockOnMainThread:(void (^)(void))block;

@end
