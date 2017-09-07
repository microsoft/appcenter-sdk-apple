#import <Foundation/Foundation.h>
#import "MSAppDelegate.h"

#if TARGET_OS_OSX
@interface MSPushAppDelegate : NSObject <MSAppDelegate, NSUserNotificationCenterDelegate>
#else
@interface MSPushAppDelegate : NSObject <MSAppDelegate>
#endif

@end
