// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter.h"
#import "AppCenterAnalytics.h"

// Internal
#import "MSACAnalyticsInternal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Event filtering service.
 */
@interface MSEventFilter : MSACServiceAbstract <MSACChannelDelegate>

/**
 * Get the unique instance.
 *
 * @return unique instance.
 */
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
