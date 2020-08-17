// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSChannelDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class MSAppCenterIngestion;
@class UIApplication;

@interface MSChannelGroupDefault () <MSChannelDelegate>

/**
 * Initializes a new `MSChannelGroupDefault` instance.
 *
 * @param ingestion An HTTP ingestion instance that is used to send batches of log items to the backend.
 *
 * @return A new `MSChannelGroupDefault` instance.
 */
- (instancetype)initWithIngestion:(nullable MSAppCenterIngestion *)ingestion;

#if !TARGET_OS_OSX

/**
 * Called when applciation is terminating.
 */
- (void)applicationWillTerminate:(UIApplication *)application;

#endif

@end

NS_ASSUME_NONNULL_END
