#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>

@import AppCenterCrashes;
@import AppCenterPush;
@import CoreLocation;

@interface AppDelegate : NSObject <NSApplicationDelegate, MSCrashesDelegate, MSPushDelegate, NSUserNotificationCenterDelegate, CLLocationManagerDelegate>

@end
