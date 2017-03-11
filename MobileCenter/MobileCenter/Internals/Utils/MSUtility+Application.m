#import "MSUtility+ApplicationPrivate.h"

@implementation MSUtility (Application)
+ (MSApplicationState)applicationState {
    
    // App extentions must not access sharedApplication.
    if (!MS_IS_APP_EXTENSION) {
        return (MSApplicationState) [[self class] sharedAppState];
    }
    return MSApplicationStateUnknown;
}

@end
