/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface SNMAnalyticsCategory : NSObject

@property(nonatomic) BOOL isEnabled;

/**
 *  Activate category for UIViewController
 */
+ (void)activateCategory;

@end

/**
 *  Should track page
 *
 *  @param viewController The current view controller
 *
 *  @return YES if should track page, NO otherwise
 */
BOOL ava_shouldTrackPageView(UIViewController *viewController);

NS_ASSUME_NONNULL_END
