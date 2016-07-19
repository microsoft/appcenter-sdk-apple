/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAConstants+Internal.h"
#import "AVADeviceLog.h"
#import "AVADeviceTracker.h"
#import "AVAUtils.h"
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>

// SDK versioning struct
typedef struct {
  uint8_t info_version;
  const char ava_version[16];
  const char ava_build[16];
} ava_info_t;

// SDK versioning
ava_info_t avalanche_library_info __attribute__((section("__TEXT,__bit_ios,regular,no_dead_strip"))) = {
    .info_version = 1, .ava_version = AVALANCHE_C_VERSION, .ava_build = AVALANCHE_C_BUILD};

@interface AVADeviceTracker ()

@property(nonatomic, readwrite) AVADeviceLog *device;

@end

@implementation AVADeviceTracker : NSObject

/**
 *  Get the current device log.
 */
- (AVADeviceLog *)device {

  // Lazy creation.
  if (!_device) {
    [self refresh];
  }
  return _device;
}

/**
 *  Refresh device characteristics.
 */
- (void)refresh {
  AVADeviceLog *newDevice = [[AVADeviceLog alloc] init];
  NSBundle *appBundle = [NSBundle mainBundle];

  // Collect device characteristics
  newDevice.sdkVersion = [self sdkVersion:avalanche_library_info.ava_version];
  newDevice.model = [self deviceModel];
  newDevice.oemName = kAVADeviceManufacturer;
  newDevice.osName = [self osName:kAVADevice];
  newDevice.osVersion = [self osVersion:kAVADevice];
  newDevice.locale = [self locale:kAVALocale];
  newDevice.timeZoneOffset = [self timeZoneOffset:[NSTimeZone localTimeZone]];
  newDevice.screenSize = [self screenSize];
  newDevice.appVersion = [self appVersion:appBundle];
  newDevice.appBuild = [self appBuild:appBundle];

  // Set the new device info
  self.device = newDevice;
}

#pragma mark - Helpers

/**
 *  Get the SDK version.
 *
 *  @param  version SDK version as const char.
 *
 *  @return The SDK version as an NSString.
 */
- (NSString *)sdkVersion:(const char[])version {
  return [NSString stringWithUTF8String:version];
}

/**
 *  Get device model.
 *
 *  @return The device model as an NSString.
 */
- (NSString *)deviceModel {
  size_t size;
  sysctlbyname("hw.machine", NULL, &size, NULL, 0);
  char *machine = malloc(size);
  sysctlbyname("hw.machine", machine, &size, NULL, 0);
  NSString *model = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
  free(machine);
  return model;
}

/**
 *  Get the OS name.
 *
 *  @param device Current UIDevice.
 *
 *  @return The OS name as an NSString.
 */
- (NSString *)osName:(UIDevice *)device {
  return device.systemName;
}

/**
 *  Get the OS version.
 *
 *  @param device Current UIDevice.
 *
 *  @return The OS version as an NSString.
 */
- (NSString *)osVersion:(UIDevice *)device {
  return device.systemVersion;
}

/**
 *  Get the device current locale.
 *
 *  @param locale Device current locale.
 *
 *  @return The device current locale as an NSString.
 */
- (NSString *)locale:(NSLocale *)currentLocale {
  return [currentLocale objectForKey:NSLocaleIdentifier];
}

/**
 *  Get the device current timezone offset (UTC as reference).
 *
 *  @param timeZone Device timezone.
 *
 *  @return The device current timezone offset as an NSNumber.
 */
- (NSNumber *)timeZoneOffset:(NSTimeZone *)timeZone {
  return @([timeZone secondsFromGMT] / 60);
}

/**
 *  Get the renedered screen size.
 *
 *  @return The size of the screen as an NSString with format "HeightxWidth".
 */
- (NSString *)screenSize {
  CGFloat scale = [UIScreen mainScreen].scale;
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  return [NSString stringWithFormat:@"%dx%d", (int)(screenSize.height * scale), (int)(screenSize.width * scale)];
}

/**
 *  Get the application version.
 *
 *  @param appBundle Application main bundle.
 *
 *  @return The application version as an NSString.
 */
- (NSString *)appVersion:(NSBundle *)appBundle {
  return [appBundle infoDictionary][@"CFBundleShortVersionString"];
}

/**
 *  Get the application build.
 *
 *  @param appBundle Application main bundle.
 *
 *  @return The application build as an NSString.
 */
- (NSString *)appBuild:(NSBundle *)appBundle {
  return [appBundle infoDictionary][@"CFBundleVersion"];
}

@end
