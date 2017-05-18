#import <Foundation/Foundation.h>

#import "MSAppDelegateForwarder.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAppDelegateForwarder ()

/**
 * Hash table containing all the delegates as weak references.
 */
@property(nonatomic, class) NSHashTable<id<MSAppDelegate>> *delegates;

/**
 * Keep track of swizzled methods.
 */
@property(nonatomic, class, readonly) NSMutableSet<NSString *> *selectorsToSwizzle;

/**
 * Keep track of the original delegate's method implementations.
 */
@property(nonatomic, class, readonly) NSMutableDictionary<NSString *, NSValue *> *originalImplementations;

/**
 * Trace buffer storing debbuging traces.
 */
@property(nonatomic, class, readonly) NSMutableArray<dispatch_block_t> *traceBuffer;

/**
 * Hold the original @see UIApplication#setDelegate: implementation.
 */
@property(nonatomic, class) IMP originalSetDelegateImp;

/**
 * Register swizzling for the given original application delegate.
 *
 * @param originalDelegate The original application delegate.
 */
+ (void)swizzleOriginalDelegate:(id<UIApplicationDelegate>)originalDelegate;

@end

NS_ASSUME_NONNULL_END
