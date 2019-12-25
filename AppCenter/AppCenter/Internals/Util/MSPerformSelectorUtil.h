// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSPerformSelectorUtil : NSObject

+ (void)performSelectorOnMainThread:(NSObject *)source withSelector:(SEL)selector withObjects:(NSObject *)objects, ...;

+ (NSInvocation *)invoke:(NSObject *)source withSelector:(NSString *)selector withObjects:(NSArray *)objects;

@end
