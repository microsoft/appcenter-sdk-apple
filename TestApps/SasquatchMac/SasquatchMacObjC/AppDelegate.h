#import <Cocoa/Cocoa.h>

@import MobileCenterCrashes;
@import MobileCenterPush;

@interface AppDelegate : NSObject <NSApplicationDelegate, MSCrashesDelegate, MSPushDelegate, NSUserNotificationCenterDelegate>

@end
