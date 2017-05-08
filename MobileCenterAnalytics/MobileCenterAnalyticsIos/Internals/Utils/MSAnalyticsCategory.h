#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
BOOL ms_shouldTrackPageView(UIViewController *viewController);

NS_ASSUME_NONNULL_END
