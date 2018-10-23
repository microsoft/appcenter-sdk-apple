#import "MSDelegateForwarder.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDelegateForwarder ()

/**
 * Hash table containing all the delegates as weak references.
 */
@property(nonatomic) NSHashTable<id<MSCustomDelegate>> *delegates;

/**
 * Keep track of original selectors to swizzle.
 */
@property(nonatomic, readonly) NSMutableSet<NSString *> *selectorsToSwizzle;

/**
 * Dictionary of deprecated original selectors indexed by their new equivalent.
 */
@property(nonatomic, readonly) NSDictionary<NSString *, NSString *> *deprecatedSelectors;

/**
 * Keep track of the original delegate's method implementations.
 */
@property(nonatomic, readonly) NSMutableDictionary<NSString *, NSValue *> *originalImplementations;

#if TARGET_OS_OSX
/**
 * Hold the original @see NSApplication#setDelegate: implementation.
 */
#else
/**
 * Hold the original @see UIApplication#setDelegate: implementation.
 */
#endif
@property(nonatomic) IMP originalSetDelegateImp;

/**
 * Register swizzling for the given original application delegate.
 *
 * @param originalDelegate The original application delegate.
 */
- (void)swizzleOriginalDelegate:(NSObject *)originalDelegate;

/**
 * Reset the app delegate forwarder, used for testing only.
 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END

