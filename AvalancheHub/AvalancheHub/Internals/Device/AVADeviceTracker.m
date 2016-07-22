/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAConstants+Internal.h"
#import "AVADeviceTracker.h"
#import "AVADeviceTrackerPrivate.h"
#import "AVAUtils.h"

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

@synthesize device = _device;

/**
 *  Get the current device log.
 */
- (AVADeviceLog *)device {
  @synchronized(self) {

    // Lazy creation.
    if (!_device) {
      [self refresh];
    }
    return _device;
  }
}

/**
 *  Set the current device log.
 */
- (void)setDevice:(AVADeviceLog *)aDevice {
  @synchronized(self) {
    _device = aDevice;
  }
}

/**
 *  Refresh device characteristics.
 */
- (void)refresh {
  @synchronized(self) {
    AVADeviceLog *newDevice = [[AVADeviceLog alloc] init];
    NSBundle *appBundle = [NSBundle mainBundle];
    CTCarrier *carrier = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];

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
    newDevice.carrierCountry = [self carrierCountry:carrier];
    newDevice.carrierName = [self carrierName:carrier];
    newDevice.appBuild = [self appBuild:appBundle];
    newDevice.appNamespace = [self appNamespace:appBundle];

    // Set the new device info
    _device = newDevice;
  }
}

#pragma mark - Helpers

- (NSString *)sdkVersion:(const char[])version {
  return [NSString stringWithUTF8String:version];
}

- (NSString *)deviceModel {
  size_t size;
  sysctlbyname("hw.machine", NULL, &size, NULL, 0);
  char *machine = malloc(size);
  sysctlbyname("hw.machine", machine, &size, NULL, 0);
  NSString *model = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
  free(machine);
  return model;
}

- (NSString *)osName:(UIDevice *)device {
  return device.systemName;
}

- (NSString *)osVersion:(UIDevice *)device {
  return device.systemVersion;
}

- (NSString *)locale:(NSLocale *)currentLocale {
  return [currentLocale objectForKey:NSLocaleIdentifier];
}

- (NSNumber *)timeZoneOffset:(NSTimeZone *)timeZone {
  return @([timeZone secondsFromGMT] / 60);
}

- (NSString *)screenSize {
  CGFloat scale = [UIScreen mainScreen].scale;
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  return [NSString stringWithFormat:@"%dx%d", (int)(screenSize.height * scale), (int)(screenSize.width * scale)];
}

- (NSString *)carrierName:(CTCarrier *)carrier {
  return ([carrier.carrierName length] > 0) ? carrier.carrierName : nil;
}

- (NSString *)carrierCountry:(CTCarrier *)carrier {
  return ([carrier.isoCountryCode length] > 0) ? carrier.isoCountryCode : nil;
}

- (NSString *)appVersion:(NSBundle *)appBundle {
  return [appBundle infoDictionary][@"CFBundleShortVersionString"];
}

- (NSString *)appBuild:(NSBundle *)appBundle {
  return [appBundle infoDictionary][@"CFBundleVersion"];
}

- (NSString *)appNamespace:(NSBundle *)appBundle {
  return [appBundle bundleIdentifier];
}

@end
