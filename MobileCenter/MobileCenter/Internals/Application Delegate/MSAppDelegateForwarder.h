#import <Foundation/Foundation.h>

#import "MSCustomAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAppDelegateForwarder : NSObject <UIApplicationDelegate, MSCustomAppDelegate>

/**
 * Enable/Disable Application forwarding.
 */
@property(nonatomic, class) BOOL enabled;

/**
 * Register method swizzling over the original App delegate for the given delegate.
 *
 * @param delegate A delegate registering its methods for swizzling.
 *
 * @discussion App delegate swizzling must be registered within the `application:didFinishLaunchingWithOptions:`
 * to avoid unpredictible behaviors. That is where the SDK is started.
 * Because it can't be activated anywhere swizzling should be registered whatever the enabled state.
 */
+ (void)registerSwizzlingForDelegate:(id<MSCustomAppDelegate>)delegate;

/**
 * Add a delegate.
 *
 * @param delegate A delegate.
 */
+ (void)addDelegate:(id<MSCustomAppDelegate>)delegate;

/**
 * Remove a delegate.
 *
 * @param delegate A delegate.
 */
+ (void)removeDelegate:(id<MSCustomAppDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
