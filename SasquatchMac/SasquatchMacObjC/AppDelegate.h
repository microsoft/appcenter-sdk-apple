#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>

@import AppCenterCrashes;
@import AppCenterPush;

@interface AppDelegate
    : NSObject <NSApplicationDelegate, MSCrashesDelegate, MSPushDelegate, NSUserNotificationCenterDelegate, CLLocationManagerDelegate>
- (void) overrideCountryCode;
@end
