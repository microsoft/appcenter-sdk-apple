// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#define MS_DISPATCH_SELECTOR(type, object, selectorName, ...)                                                                              \
  ({                                                                                                                                       \
    void *results;                                                                                                                         \
    [[MSDispatcherUtil performSelector:object withSelector:@ #selectorName withObjects:@[ __VA_ARGS__ ]] getReturnValue:&results];         \
    (type) results;                                                                                                                        \
  })

@interface MSDispatcherUtil : NSObject

+ (void)performBlockOnMainThread:(void (^)(void))block;

+ (NSInvocation *)performSelector:(id)source withSelector:(NSString *)selector withObjects:(NSArray *)objects;

@end
