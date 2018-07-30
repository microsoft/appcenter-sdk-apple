#import <Cocoa/Cocoa.h>

@import AppCenterCrashes;
@import AppCenterPush;

@interface AppDelegate : NSObject <NSApplicationDelegate, MSCrashesDelegate, MSPushDelegate, NSUserNotificationCenterDelegate>

@end
