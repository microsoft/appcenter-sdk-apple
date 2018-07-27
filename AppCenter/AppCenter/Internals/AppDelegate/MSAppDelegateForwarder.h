#import "MSCustomApplicationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Enum used to represent all kind of executors running the completion handler.
 */
typedef NS_OPTIONS(NSUInteger, MSCompletionExecutor) {
  MSCompletionExecutorNone = (1 << 0),
  MSCompletionExecutorOriginal = (1 << 1),
  MSCompletionExecutorCustom = (1 << 2),
  MSCompletionExecutorForwarder = (1 << 3)
};

@interface MSAppDelegateForwarder : NSObject <MSCustomApplicationDelegate>

/**
 * Enable/Disable Application forwarding.
 */
@property(nonatomic, class) BOOL enabled;

/**
 * Add a delegate. This method is thread safe.
 *
 * @param delegate A delegate.
 */
+ (void)addDelegate:(id<MSCustomApplicationDelegate>)delegate;

/**
 * Remove a delegate. This method is thread safe.
 *
 * @param delegate A delegate.
 */
+ (void)removeDelegate:(id<MSCustomApplicationDelegate>)delegate;

/**
 * Add an app delegate selector to swizzle.
 *
 * @param selector An app delegate selector to swizzle.
 *
 * @discussion Due to the early registration of swizzling on the original app
 * delegate each custom delegate must sign up for selectors to swizzle within
 * the `load` method of a category over the @see MSAppDelegateForwarder class.
 */
+ (void)addAppDelegateSelectorToSwizzle:(SEL)selector;

/**
 * Flush debugging traces accumulated until now.
 */
+ (void)flushTraceBuffer;

@end

NS_ASSUME_NONNULL_END
