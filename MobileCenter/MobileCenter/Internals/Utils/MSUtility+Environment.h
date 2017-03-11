#import <Foundation/Foundation.h>
#import "MSUtil.h"

/**
 * Utility class that is used throughout the SDK.
 */
@interface MSUtility (Environment)

/**
 * Detect the environment that the app is running in.
 * @return the MSEnvironment of the app.
 */
+ (MSEnvironment)currentAppEnvironment;

@end

