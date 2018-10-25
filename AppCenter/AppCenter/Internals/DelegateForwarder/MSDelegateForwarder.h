#import <Foundation/Foundation.h>
@protocol MSCustomDelegate;

@interface MSDelegateForwarder : NSObject

/**
 * Enable/Disable Application forwarding.
 */
@property(nonatomic) BOOL enabled;

/**
 * Hash table containing all the delegates as weak references.
 */
@property(nonatomic) NSHashTable<id<MSCustomDelegate>> *delegates;

/**
 * Hold the original setDelegate implementation.
 */
@property(nonatomic) IMP originalSetDelegateImp;

/**
 * Keep track of the original delegate's method implementations.
 */
@property(nonatomic, readonly) NSMutableDictionary<NSString *, NSValue *> *originalImplementations;

/**
 * Dictionary of deprecated original selectors indexed by their new equivalent.
 */
@property(nonatomic) NSDictionary<NSString *, NSString *> *deprecatedSelectors;

/**
 * Returns the singleton instance of MSDelegateForwarder.
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
