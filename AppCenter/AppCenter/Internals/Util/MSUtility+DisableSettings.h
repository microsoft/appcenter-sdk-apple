#import <Foundation/Foundation.h>
#import "MSUtility.h"

@class MSServiceInternal;

/**
 * Utility class that is used to determine what modules to disable. Designed to be used with test cloud.
 * Note that in this case, "disabling" means "not starting," and is distinct from setting its enabled state
 * to NO.
 */
@interface MSUtility (MSDisableSettings)

/**
 * Determines whether a service should be disabled.
 *
 * @param serviceName The service name to consider for disabling.
 *
 * @return YES if the service should be disabled.
 */
+ (BOOL)shouldDisable:(NSString*)serviceName;

@end
