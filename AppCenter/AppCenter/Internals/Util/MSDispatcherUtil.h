// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#define MS_DISPATCH_SELECTOR(declaration, object, selectorName, ...)                                                                       \
  ({                                                                                                                                       \
    SEL selector = NSSelectorFromString(@ #selectorName);                                                                                  \
    IMP impl = [object methodForSelector:selector];                                                                                        \
    (declaration impl)(object, selector, ##__VA_ARGS__);                                                                                   \
  })

@interface MSDispatcherUtil : NSObject

+ (void)performBlockOnMainThread:(void (^)(void))block;

@end
