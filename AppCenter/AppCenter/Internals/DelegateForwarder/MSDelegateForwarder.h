#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSCustomDelegate;

/**
 * Enum used to represent all kind of executors running a completion handler.
 */
typedef NS_OPTIONS(NSUInteger, MSCompletionExecutor) {
  MSCompletionExecutorNone = (1 << 0),
  MSCompletionExecutorOriginal = (1 << 1),
  MSCompletionExecutorCustom = (1 << 2),
  MSCompletionExecutorForwarder = (1 << 3)
};

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

// TODO SEL can be stored as NSValue in dictionaries for a better efficiency.
/**
 * Keep track of the original delegate's method implementations.
 */
@property(nonatomic, readonly) NSMutableDictionary<NSString *, NSValue *> *originalImplementations;

/**
 * Dictionary of deprecated original selectors indexed by their new equivalent.
 */
@property(nonatomic) NSDictionary<NSString *, NSString *> *deprecatedSelectors;

/**
 * Return the singleton instance of a delegate forwarder.
 *
 * @return The delegate forwarder instance.
 *
 * @discussion This method is abstract and needs to be overwritten by subclasses.
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
- (void)addDelegateSelectorToSwizzle:(SEL)selector;

/**
 * Flush debugging traces accumulated until now.
 */
+ (void)flushTraceBuffer;

/**
 * Set the enabled state from the application plist file.
 *
 * @param plistKey Plist key for the forwarder enabled state.
 */
- (void)setEnabledFromPlistForKey:(NSString *)plistKey;

@end

NS_ASSUME_NONNULL_END
