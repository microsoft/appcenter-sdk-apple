// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter.h"
#import "AppCenterAnalytics.h"

// Internal
#import "MSAnalyticsInternal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Event filtering service.
 */
@interface MSEventFilter : MSServiceAbstract <MSChannelDelegate>

/**
 * Get the unique instance.
 *
 * @return unique instance.
 */
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
