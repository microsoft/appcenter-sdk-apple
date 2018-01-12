#import "MSServiceAbstract.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * App Center analytics service.
 */
@interface MSAnalytics : MSServiceAbstract

// Events values limitations
@property (class, nonatomic, assign, readonly) NSUInteger minEventNameLength; //: 1;
@property (class, nonatomic, assign, readonly) NSUInteger maxEventNameLength; //: 256;
@property (class, nonatomic, assign, readonly) NSUInteger maxPropertiesPerEvent; //: 5;
@property (class, nonatomic, assign, readonly) NSUInteger minPropertyKeyLength; //: 1;
@property (class, nonatomic, assign, readonly) NSUInteger maxPropertyKeyLength; //: 64;
@property (class, nonatomic, assign, readonly) NSUInteger maxPropertyValueLength; //: 64;

/**
 * Track an event.
 *
 * @param eventName  event name.
 */
+ (void)trackEvent:(NSString *)eventName;

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 */
+ (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

@end

NS_ASSUME_NONNULL_END
