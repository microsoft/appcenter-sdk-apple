#import <Foundation/Foundation.h>

/**
 *  Protocol declaring service logic.
 */
@protocol MSService <NSObject>

/**
 * Enable/disable this service.
 * The state is persisted in the device's storage across application launches.
 *
 * @param isEnabled whether this service is enabled or not.
 *
 * @see isEnabled
 */
+ (void)setEnabled:(BOOL)isEnabled;

/**
 * Is this service enabled.
 *
 * @return a boolean whether this service is enabled or not.
 *
 * @see setEnabled:
 */
+ (BOOL)isEnabled;

@end
