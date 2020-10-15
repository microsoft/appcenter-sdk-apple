// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACUtility+Date.h"

/**
 * Utility class that is used throughout the SDK.
 * Date part.
 */
@interface MSACUtility (DatePrivate)

/**
 * Method to reset the nsdateformatter singleton when running unit tests only.
 */
+ (void)resetDateFormatterInstance;

@end
