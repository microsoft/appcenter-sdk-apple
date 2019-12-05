// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface NSObject (PerformSelectorOnMainThreadMultipleArgs)

/**
 * performSelectorOnMainThread with multiple parameters.
 *
 * @param selector A Selector that identifies the method to invoke. The method should not have a significant return value and should
 * take a single argument of type id, or no arguments.
 * @param waitUntilDone A Boolean that specifies whether the current thread blocks until after the specified selector is performed
 * on the receiver on the main thread.
 * @param withObjects Arguments to pass to the method when it is invoked. Must contain the last element [NSNull null] to indicate
 * the end of the sequence.
 *
 */
-(void)performSelectorOnMainThread:(SEL)selector waitUntilDone:(BOOL)wait withObjects:(NSObject *)objects, ... NS_REQUIRES_NIL_TERMINATION;

@end
