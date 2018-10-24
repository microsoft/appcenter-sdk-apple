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

// TODO doc.
@property(nonatomic, nullable) NSMutableArray<dispatch_block_t> *traceBuffer;

/**
 * Reset the app delegate forwarder, used for testing only.
 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
