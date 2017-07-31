#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import "MSNSAppDelegate.h"
#else
#import "MSUIAppDelegate.h"
#endif

#if TARGET_OS_OSX
@interface MSPushAppDelegate : NSObject <MSAppDelegate, NSUserNotificationCenterDelegate>
#else
@interface MSPushAppDelegate : NSObject <MSAppDelegate>
#endif

@end
