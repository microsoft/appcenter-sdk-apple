// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSUtility.h"

/*
 * Workaround for exporting symbols from category object files.
 */
extern NSString *MSUtilityObjectSelectorCategory;

@interface MSUtility (PerformSelectorOnMainThreadMultipleArgs)

/**
 * performSelectorOnMainThread with multiple parameters.
 *
 * @param source Source of action.
 * @param selector A Selector that identifies the method to invoke. The method should not have a significant return value and should
 * take a single argument of type id, or no arguments.
 * @param objects Arguments to pass to the method when it is invoked. Must contain the last element [NSNull null] to indicate
 * the end of the sequence.
 *
 */
+ (void)performSelectorOnMainThread:(NSObject* )source withSelector:(SEL)selector withObjects:(NSObject *)objects, ... ;

@end
