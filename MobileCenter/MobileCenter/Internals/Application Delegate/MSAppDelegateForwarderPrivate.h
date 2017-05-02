#import <Foundation/Foundation.h>

#import "MSAppDelegateForwarder.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAppDelegateForwarder ()

/**
 * Hash table containing all the delegates as weak references.
 */
@property(nonatomic, class) NSHashTable<id<MSCustomAppDelegate>> *delegates;

/**
 * Keep track of swizzled methods.
 */
@property(nonatomic, class) NSMutableArray<NSString *> *swizzledSelectors;

/**
 * Swizzle the given selector.
 *
 * @param selector A selector to swizzle.
 *
 * @discussion App delegate swizzling must be registered within the `application:didFinishLaunchingWithOptions:`
 * to avoid unpredictible behaviors. That's were the SDK is started.
 * Because it can't be activated anywhere swizzling should be registered whatever the enabled state.
 */
+ (void)swizzleSelector:(SEL)selector;

@end

NS_ASSUME_NONNULL_END
