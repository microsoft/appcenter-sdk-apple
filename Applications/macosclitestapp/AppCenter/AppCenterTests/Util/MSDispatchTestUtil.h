// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSDispatchTestUtil : NSObject

/**
 * Suspends the dispatch queue and waits for current operations to complete.
 *
 * @param dispatchQueue The dispatch queue to suspend.
 */
+ (void)awaitAndSuspendDispatchQueue:(dispatch_queue_t)dispatchQueue;

@end

NS_ASSUME_NONNULL_END
