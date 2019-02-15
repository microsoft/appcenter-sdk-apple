#import <Foundation/Foundation.h>

/**
 *  Protocol declaring service logic.
 */
@protocol MSService <NSObject>

/**
 * Enable/disable this service.
 * The state is stored on disk, so it won't change in following app launches.
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
