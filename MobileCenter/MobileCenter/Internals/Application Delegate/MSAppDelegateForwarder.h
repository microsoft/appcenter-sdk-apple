#import <Foundation/Foundation.h>

#import "MSAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAppDelegateForwarder : NSObject <UIApplicationDelegate, MSAppDelegate>

/**
 * Enable/Disable Application forwarding.
 */
@property(nonatomic, class) BOOL enabled;

/**
 * Add a delegate. This method is thread safe.
 *
 * @param delegate A delegate.
 */
+ (void)addDelegate:(id<MSAppDelegate>)delegate;

/**
 * Remove a delegate. This method is thread safe.
 *
 * @param delegate A delegate.
 */
+ (void)removeDelegate:(id<MSAppDelegate>)delegate;

/**
 * Add an app delegate selector to swizzle.
 *
 * @param selector An app delegate selector to swizzle.
 *
 * @discussion Due to the early registration of swizzling on the original app delegate
 * each custom delegate must sign up for selectors to swizzle within the `load` method of a category over
 * the @see MSAppDelegateForwarder class.
 */
+ (void)addAppDelegateSelectorToSwizzle:(SEL)selector;

@end

NS_ASSUME_NONNULL_END
