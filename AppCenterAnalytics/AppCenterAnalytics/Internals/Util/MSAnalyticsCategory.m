#import <objc/runtime.h>

#import "MSAnalyticsCategory.h"
#import "MSAnalyticsInternal.h"

static NSString *const kMSViewControllerSuffix = @"ViewController";
static NSString *MSMissedPageViewName;

#if TARGET_OS_OSX
@implementation NSViewController (PageViewLogging)
#else
@implementation UIViewController (PageViewLogging)
#endif

+ (void)swizzleViewWillAppear {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class class = [self class];

// Get selectors.
#if TARGET_OS_OSX
    SEL originalSelector = NSSelectorFromString(@"viewWillAppear");
#else
    SEL originalSelector = NSSelectorFromString(@"viewWillAppear:");
#endif

    SEL swizzledSelector = @selector(ms_viewWillAppear:);

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    method_exchangeImplementations(originalMethod, swizzledMethod);
  });
}

#pragma mark - Method Swizzling

- (void)ms_viewWillAppear:(BOOL)animated {
  [self ms_viewWillAppear:animated];
  if ([MSAnalytics isAutoPageTrackingEnabled]) {

    if (!ms_shouldTrackPageView(self))
      return;

    // By default, use class name for the page name.
    NSString *pageViewName = NSStringFromClass([self class]);

    // Remove module name on swift classes.
    pageViewName = [[pageViewName componentsSeparatedByString:@"."] lastObject];

    // Remove suffix if any.
    if ([pageViewName hasSuffix:kMSViewControllerSuffix] && [pageViewName length] > [kMSViewControllerSuffix length]) {
      pageViewName = [pageViewName substringToIndex:[pageViewName length] - [kMSViewControllerSuffix length]];
    }

    // Track page if ready.
    if ([MSAnalytics sharedInstance].available) {

      // Reset cached page.
      MSMissedPageViewName = nil;

      // Track page.
      [MSAnalytics trackPage:pageViewName];
    } else {

      // Store the page name for retroactive tracking.
      // For instance if the service becomes enabled after the view appeared.
      MSMissedPageViewName = pageViewName;
    }
  }
}

@end

#if TARGET_OS_OSX
BOOL ms_shouldTrackPageView(NSViewController *viewController) {
#else
BOOL ms_shouldTrackPageView(UIViewController *viewController) {
#endif

  // For container view controllers, auto page tracking is disabled(to avoid noise).
  NSSet *viewControllerSet = [NSSet setWithArray:@[
#if TARGET_OS_OSX
    @"NSTabViewController", @"NSSplitViewController", @"NSPageController"
#else
    @"UINavigationController", @"UITabBarController", @"UISplitViewController", @"UIInputWindowController", @"UIPageViewController"
#endif
  ]];
  NSString *className = NSStringFromClass([viewController class]);

  return ![viewControllerSet containsObject:className];
}

@implementation MSAnalyticsCategory

+ (void)activateCategory {
#if TARGET_OS_OSX
  [NSViewController swizzleViewWillAppear];
#else
  [UIViewController swizzleViewWillAppear];
#endif
}

+ (NSString *)missedPageViewName {
  return MSMissedPageViewName;
}

@end
