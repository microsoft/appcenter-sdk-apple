/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAnalytics.h"
#import "AVAAnalyticsCategory.h"
#import <objc/runtime.h>

@implementation UIViewController (PageViewLogging)

+ (void)swizzleViewWillAppear {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class class = [self class];

    // get selectors
    SEL originalSelector = @selector(viewWillAppear:);
    SEL swizzledSelector = @selector(ava_viewWillAppear:);

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    method_exchangeImplementations(originalMethod, swizzledMethod);
  });
}

#pragma mark - Method Swizzling

- (void)ava_viewWillAppear:(BOOL)animated {
  [self ava_viewWillAppear:animated];
  if ([AVAAnalytics isAutoPageTrackingEnabled]) {

    if (!ava_shouldTrackPageView(self))
      return;

    // By default, use class name for the page name
    NSString *pageViewName = NSStringFromClass([self class]);

    // Track page
    [AVAAnalytics trackPage:pageViewName withProperties:nil];
  }
}

@end

BOOL ava_shouldTrackPageView(UIViewController *viewController) {

  // For container view controllers, auto page tracking is disabled(to avoid
  // noise).
  NSSet *viewControllerSet = [NSSet setWithArray:@[
    @"UINavigationController",
    @"UITabBarController",
    @"UISplitViewController",
    @"UIInputWindowController",
    @"UIPageViewController"
  ]];
  NSString *className = NSStringFromClass([viewController class]);

  return ![viewControllerSet containsObject:className];
}

@implementation AVAAnalyticsCategory

+ (void)activateCategory {
  [UIViewController swizzleViewWillAppear];
}

@end
