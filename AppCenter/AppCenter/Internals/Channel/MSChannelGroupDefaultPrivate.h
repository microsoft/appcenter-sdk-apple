// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSChannelDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class MSAppCenterIngestion;

@interface MSChannelGroupDefault () <MSChannelDelegate>

/**
 * Initializes a new `MSChannelGroupDefault` instance.
 *
 * @param ingestion An HTTP ingestion instance that is used to send batches of log items to the backend.
 *
 * @return A new `MSChannelGroupDefault` instance.
 */
- (instancetype)initWithIngestion:(nullable MSAppCenterIngestion *)ingestion;

/**
* Semaphore for exclusion with "startDelayedCrashProcessing" method.
*/
@property dispatch_semaphore_t delayedProcessingSemaphore;

@end

NS_ASSUME_NONNULL_END
