#import <Foundation/Foundation.h>
#import "MSCrashHandlerSetupDelegate.h"

/**
 * This general class allows wrappers to supplement the Crashes SDK with their own
 * behavior.
 */
@interface MSWrapperCrashesHelper : NSObject

+ (void) setCrashHandlerSetupDelegate:(id<MSCrashHandlerSetupDelegate>)delegate;
+ (id<MSCrashHandlerSetupDelegate>) getCrashHandlerSetupDelegate;

@end
