#import "MSUtility+Application.h"

/**
 * Utility class that is used throughout the SDK.
 * Application private part.
 */
@interface MSUtility (ApplicationPrivate)

/**
 * Get the shared app state.
 *
 * @return The shared app state.
 *
 * @discussion This method is exposed for testing purposes. The shared app state is resolved at runtime by this method which makes the
 * UIApplication not mockable. This method is meant to be stubbed in tests to inject the desired application states.
 */
#if TARGET_OS_OSX
+ (MSApplicationState)sharedAppState;
#else
+ (UIApplicationState)sharedAppState;
#endif

@end
