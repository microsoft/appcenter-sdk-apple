#import "MSDelegateForwarder.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDelegateForwarder ()

/**
 * Keep track of original selectors to swizzle.
 */
@property(nonatomic, readonly) NSMutableSet<NSString *> *selectorsToSwizzle;

// TODO doc.
@property(nonatomic, nullable) NSMutableArray<dispatch_block_t> *traceBuffer;

/**
 * Reset the app delegate forwarder, used for testing only.
 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
