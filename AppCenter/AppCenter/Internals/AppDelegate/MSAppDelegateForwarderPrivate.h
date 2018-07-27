#import "MSAppDelegateForwarder.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAppDelegateForwarder ()

/**
 * Hash table containing all the delegates as weak references.
 */
@property(nonatomic, class)
    NSHashTable<id<MSCustomApplicationDelegate>> *delegates;

/**
 * Keep track of original selectors to swizzle.
 */
@property(nonatomic, class, readonly)
    NSMutableSet<NSString *> *selectorsToSwizzle;

/**
 * Dictionary of deprecated original selectors indexed by their new equivalent.
 */
@property(nonatomic, class, readonly)
    NSDictionary<NSString *, NSString *> *deprecatedSelectors;

/**
 * Keep track of the original delegate's method implementations.
 */
@property(nonatomic, class, readonly)
    NSMutableDictionary<NSString *, NSValue *> *originalImplementations;

#if TARGET_OS_OSX
/**
 * Hold the original @see NSApplication#setDelegate: implementation.
 */
#else
/**
 * Hold the original @see UIApplication#setDelegate: implementation.
 */
#endif
@property(nonatomic, class) IMP originalSetDelegateImp;

/**
 * Returns the singleton instance of MSAppDelegateForwarder.
 */
+ (instancetype)sharedInstance;

/**
 * Register swizzling for the given original application delegate.
 *
 * @param originalDelegate The original application delegate.
 */
+ (void)swizzleOriginalDelegate:(id<MSApplicationDelegate>)originalDelegate;

/**
 * Reset the app delegate forwarder, used for testing only.
 */
+ (void)reset;

@end

NS_ASSUME_NONNULL_END
