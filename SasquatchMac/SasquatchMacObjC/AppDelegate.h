// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>

@import AppCenterCrashes;

@interface AppDelegate : NSObject <NSApplicationDelegate, MSACCrashesDelegate, CLLocationManagerDelegate>

- (void)overrideCountryCode;

@end
