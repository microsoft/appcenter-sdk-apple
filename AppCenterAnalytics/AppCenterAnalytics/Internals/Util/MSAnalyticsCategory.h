#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface MSAnalyticsCategory : NSObject

/**
 * Activate category for UIViewController.
 */
+ (void)activateCategory;

/**
 * Get the last missed page view name while available.
 *
 * @return the last page view name. Can be nil if no name available or the page has already been tracked.
 */
+ (nullable NSString *)missedPageViewName;

@end

/**
 * Should track page
 *
 * @param viewController The current view controller
 *
 * @return YES if should track page, NO otherwise
 */
#if TARGET_OS_OSX
BOOL ms_shouldTrackPageView(NSViewController *viewController);
#else
BOOL ms_shouldTrackPageView(UIViewController *viewController);
#endif

NS_ASSUME_NONNULL_END
