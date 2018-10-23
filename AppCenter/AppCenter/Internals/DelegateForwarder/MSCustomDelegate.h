NS_ASSUME_NONNULL_BEGIN

/**
 * Custom delegate.
 *
 * @discussion Delegates here are using swizzling. Any delegate that can be registered through the notification center should not be
 * registered through swizzling. Due to the early registration of swizzling on the original app delegate each custom delegate must sign up
 * for selectors to swizzle within the `load` method of a category over the @see MSDelegateForwarder class.
 */
@protocol MSCustomDelegate <NSObject>
@end

NS_ASSUME_NONNULL_END
