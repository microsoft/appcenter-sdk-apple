#import <Foundation/Foundation.h>
#import "MSCrashHandlerSetupDelegate.h"

/**
 * This general class allows wrappers to supplement the Crashes SDK with their own
 * behavior.
 */
@interface MSWrapperCrashesHelper : NSObject

@property(weak, nonatomic) id<MSCrashHandlerSetupDelegate> delegate;

+ (id) sharedInstance;

@end
