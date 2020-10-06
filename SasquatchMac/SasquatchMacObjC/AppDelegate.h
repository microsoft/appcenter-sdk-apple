// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>

@import AppCenterCrashes;
@import AppCenterPush;

@interface AppDelegate
    : NSObject <NSApplicationDelegate, MSACCrashesDelegate, MSPushDelegate, NSUserNotificationCenterDelegate, CLLocationManagerDelegate>

- (void) overrideCountryCode;

@end
