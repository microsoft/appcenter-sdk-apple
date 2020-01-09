// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSDispatcherUtil : NSObject

+ (void)performBlockOnMainThread:(void (^)(void))block;

@end
