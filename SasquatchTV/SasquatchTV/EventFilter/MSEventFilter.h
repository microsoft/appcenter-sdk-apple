// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@import AppCenter;
@import AppCenterAnalytics;

NS_ASSUME_NONNULL_BEGIN

/**
 * Event filtering service.
 */
@interface MSEventFilter : MSACServiceAbstract

/**
 * Get the unique instance.
 *
 * @return unique instance.
 */
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
