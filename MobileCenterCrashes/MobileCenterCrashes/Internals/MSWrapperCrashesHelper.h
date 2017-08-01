#import <Foundation/Foundation.h>
#import "MSCrashHandlerSetupDelegate.h"

/**
 * This general class allows wrappers to supplement the Crashes SDK with their own
 * behavior.
 */
@interface MSWrapperCrashesHelper : NSObject

/**
 * Sets the crash handler setup delegate.
 */
+ (void) setCrashHandlerSetupDelegate:(id<MSCrashHandlerSetupDelegate>)delegate;

/**
 * Gets the crash handler setup delegate.
 */
+ (id<MSCrashHandlerSetupDelegate>) getCrashHandlerSetupDelegate;

@end
