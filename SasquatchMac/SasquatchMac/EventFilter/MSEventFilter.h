@import AppCenter;
@import AppCenterAnalytics;

NS_ASSUME_NONNULL_BEGIN

/**
 * Event filtering service.
 */
@interface MSEventFilter : MSServiceAbstract <MSChannelDelegate>

/**
 * Get the unique instance.
 *
 * @return unique instance.
 */
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
