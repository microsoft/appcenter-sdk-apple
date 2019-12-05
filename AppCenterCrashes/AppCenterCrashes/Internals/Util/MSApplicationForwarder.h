// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSApplicationForwarder : NSObject

/**
 * Activate category for UIViewController.
 */
+ (void)registerForwarding;

@end

NS_ASSUME_NONNULL_END
