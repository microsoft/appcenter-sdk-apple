#import <Foundation/Foundation.h>
@protocol MSCustomDelegate;

@interface MSDelegateForwarder : NSObject

/**
 * Hold the original setDelegate implementation.
 */
@property(nonatomic) IMP originalSetDelegateImp;

/**
 * Enable/Disable Application forwarding.
 */
@property(nonatomic) BOOL enabled;

/**
 * Keep track of the original delegate's method implementations.
 */
@property(nonatomic, readonly) NSMutableDictionary<NSString *, NSValue *> *originalImplementations;

/**
 * Returns the singleton instance of MSAppDelegateForwarder.
 */
+ (instancetype)sharedInstance;

/**
 * Register swizzling for the given original application delegate.
 *
 * @param originalDelegate The original application delegate.
 */
- (void)swizzleOriginalDelegate:(NSObject *)originalDelegate;

/**
 * Add a delegate. This method is thread safe.
 *
 * @param delegate A delegate.
 */
- (void)addDelegate:(id<MSCustomDelegate>)delegate;

/**
 * Remove a delegate. This method is thread safe.
 *
 * @param delegate A delegate.
 */
- (void)removeDelegate:(id<MSCustomDelegate>)delegate;

/**
 * Add an app delegate selector to swizzle.
 *
 * @param selector An app delegate selector to swizzle.
 *
 * @discussion Due to the early registration of swizzling on the original app delegate each custom delegate must sign up for selectors to
 * swizzle within the @c load method of a category over the @see MSAppDelegateForwarder class.
 */
- (void)addAppDelegateSelectorToSwizzle:(SEL)selector;

/**
 * Flush debugging traces accumulated until now.
 */
- (void)flushTraceBuffer;

@end
