/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMConstants+Internal.h"
#import "SNMDeviceTracker.h"
#import "SNMDeviceTrackerPrivate.h"
#import "SNMUtils.h"

// SDK versioning struct.
typedef struct {
  uint8_t info_version;
  const char SNM_version[16];
  const char SNM_build[16];
} SNM_info_t;

// SDK versioning.
SNM_info_t SNMlanche_library_info __attribute__((section("__TEXT,__bit_ios,regular,no_dead_strip"))) = {
    .info_version = 1, .SNM_version = SONOMA_C_VERSION, .SNM_build = SONOMA_C_BUILD};

@implementation SNMDeviceTracker : NSObject

@synthesize device = _device;

/**
 *  Get the current device log.
 */
- (SNMDevice *)device {
  @synchronized(self) {

    // Lazy creation.
    if (!_device) {
      [self refresh];
    }
    return _device;
  }
}

/**
 *  Refresh device properties.
 */
- (void)refresh {
  @synchronized(self) {
    SNMDevice *newDevice = [[SNMDevice alloc] init];
    NSBundle *appBundle = [NSBundle mainBundle];
    CTCarrier *carrier = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];

    // Collect device properties.
    newDevice.sdkVersion = [self sdkVersion:SNMlanche_library_info.SNM_version];
    newDevice.model = [self deviceModel];
    newDevice.oemName = kSNMDeviceManufacturer;
    newDevice.osName = [self osName:kSNMDevice];
    newDevice.osVersion = [self osVersion:kSNMDevice];
    newDevice.locale = [self locale:kSNMLocale];
    newDevice.timeZoneOffset = [self timeZoneOffset:[NSTimeZone localTimeZone]];
    newDevice.screenSize = [self screenSize];
    newDevice.appVersion = [self appVersion:appBundle];
    newDevice.carrierCountry = [self carrierCountry:carrier];
    newDevice.carrierName = [self carrierName:carrier];
    newDevice.appBuild = [self appBuild:appBundle];
    newDevice.appNamespace = [self appNamespace:appBundle];

    // Set the new device info.
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
