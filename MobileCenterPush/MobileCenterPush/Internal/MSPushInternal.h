#import "MSPush.h"
#import "MSServiceInternal.h"
#import "MSPushDelegate.h"
#import "MSChannelDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSPush () <MSServiceInternal, MSChannelDelegate>

/**
 * Validate keys and values of properties.
 *
 * @return YES if properties have valid keys and values, NO otherwise.
 */
- (BOOL)validateProperties:(NSDictionary<NSString *, NSString *> *)properties;

+ (void)setDelegate:(nullable id <MSPushDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
