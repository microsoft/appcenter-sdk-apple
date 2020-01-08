// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSPerformSelectorUtil : NSObject

+ (void)performBlockOnMainThread:(void (^)(void))block;

@end
