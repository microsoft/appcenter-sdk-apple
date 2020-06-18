// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDeviceTracker.h"
#import "MSAppCenterUserDefaults.h"
#import "MSConstants+Internal.h"
#import "MSDeviceHistoryInfo.h"
#import "MSDeviceTrackerPrivate.h"
#import "MSUtility+Application.h"
#import "MSUtility+Date.h"
#import "MSUtility.h"
#import "MSWrapperSdkInternal.h"

static NSUInteger const kMSMaxDevicesHistoryCount = 5;

@interface MSDeviceTracker ()

// We need a private setter for the device to avoid the warning that is related to direct access of ivars.
@property(nonatomic) MSDevice *device;

@end

@implementation MSDeviceTracker : NSObject

static BOOL needRefresh = YES;
static MSWrapperSdk *wrapperSdkInformation = nil;
static NSString *overriddenCountryCode = nil;

/**
 * Singleton.
 */
static dispatch_once_t onceToken;
static MSDeviceTracker *sharedInstance = nil;

#pragma mark - Initialisation

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    sharedInstance = [[MSDeviceTracker alloc] init];
  });
  return sharedInstance;
}

+ (void)resetSharedInstance {
  onceToken = 0;
  sharedInstance = nil;

  // Reset state of global variables.
  // FIXME: move it to shared instance.
  needRefresh = YES;
  wrapperSdkInformation = nil;
  overriddenCountryCode = nil;
}

- (instancetype)init {
  if ((self = [super init])) {

    // Restore past sessions from NSUserDefaults.
    NSData *devices = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSPastDevicesKey];
    if (devices != nil) {
      NSArray *arrayFromData = (NSArray *)[[MSUtility unarchiveKeyedData:devices] mutableCopy];

      // If array is not nil, create a mutable version.
      if (arrayFromData != nil) {
        _deviceHistory = [NSMutableArray arrayWithArray:arrayFromData];
      }
    }

    // Create new array and create device info in case we don't have any from disk.
    if (_deviceHistory == nil) {
      _deviceHistory = [NSMutableArray<MSDeviceHistoryInfo *> new];
    }

    // This will instantiate the device property to make sure we have a history.
    [self device];
  }
  return self;
}

- (void)setWrapperSdk:(MSWrapperSdk *)wrapperSdk {
  @synchronized(self) {
    wrapperSdkInformation = wrapperSdk;
    needRefresh = YES;

    // Replace the last device without wrapperSdk in the UserDefaults with an updated info.
    [self.deviceHistory removeLastObject];
    [self device];
  }
}

- (void)setCountryCode:(NSString *)countryCode {
  @synchronized(self) {
    overriddenCountryCode = countryCode;
    needRefresh = YES;
  }
}

+ (void)refreshDeviceNextTime {
  @synchronized([MSDeviceTracker sharedInstance]) {
    needRefresh = YES;
  }
}

/**
 *  Get the current device log.
 */
- (MSDevice *)device {
  @synchronized(self) {

    // Lazy creation in case the property hasn't been set yet.
    if (!_device || needRefresh) {

      // Get new device info.
      _device = [self updatedDevice];

      // Create new MSDeviceHistoryInfo.
      MSDeviceHistoryInfo *deviceHistoryInfo = [[MSDeviceHistoryInfo alloc] initWithTimestamp:[NSDate date] andDevice:_device];

      // Insert new MSDeviceHistoryInfo at the proper index to keep self.deviceHistory sorted.
      NSUInteger newIndex = [self.deviceHistory indexOfObject:deviceHistoryInfo
                                                inSortedRange:(NSRange){0, [self.deviceHistory count]}
                                                      options:NSBinarySearchingInsertionIndex
                                              usingComparator:^(MSDeviceHistoryInfo *a, MSDeviceHistoryInfo *b) {
                                                return [a.timestamp compare:b.timestamp];
                                              }];
      [self.deviceHistory insertObject:deviceHistoryInfo atIndex:newIndex];

      // Remove first (the oldest) item if reached max limit.
      if ([self.deviceHistory count] > kMSMaxDevicesHistoryCount) {
        [self.deviceHistory removeObjectAtIndex:0];
      }

      // Persist the device history in NSData format.
      [MS_APP_CENTER_USER_DEFAULTS setObject:[MSUtility archiveKeyedData:self.deviceHistory] forKey:kMSPastDevicesKey];
    }
    return _device;
  }
}

/**
 * Refresh device properties.
 */
- (MSDevice *)updatedDevice {
  @synchronized(self) {
    MSDevice *newDevice = [MSDevice new];
#if TARGET_OS_IOS
    CTTelephonyNetworkInfo *telephonyNetworkInfo = [CTTelephonyNetworkInfo new];
    CTCarrier *carrier;

    // The CTTelephonyNetworkInfo.serviceSubscriberCellularProviders method crash because of an issue in iOS 12.0
    // It was fixed in iOS 12.1
    if (@available(iOS 12.1, *)) {
      NSDictionary<NSString *, CTCarrier *> *carriers = [telephonyNetworkInfo serviceSubscriberCellularProviders];
      carrier = [self firstCarrier:carriers];
    } else if (@available(iOS 12, *)) {
      NSDictionary<NSString *, CTCarrier *> *carriers = [telephonyNetworkInfo valueForKey:@"serviceSubscriberCellularProvider"];
      carrier = [self firstCarrier:carriers];
    }

    // Use the old API as fallback if new one doesn't work.
    if (carrier == nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      carrier = [telephonyNetworkInfo subscriberCellularProvider];
#pragma clang diagnostic pop
    }
#endif

    // Collect device properties.
    newDevice.sdkName = [MSUtility sdkName];
    newDevice.sdkVersion = [MSUtility sdkVersion];
    newDevice.model = [self deviceModel];
    newDevice.oemName = kMSDeviceManufacturer;
#if TARGET_OS_OSX || TARGET_OS_MACCATALYST
    newDevice.osName = [self osName];
#else
    newDevice.osName = [self osName:MS_DEVICE];
#endif
#if TARGET_OS_OSX
    newDevice.osVersion = [self osVersion];
#else
    newDevice.osVersion = [self osVersion:MS_DEVICE];
#endif
    newDevice.osBuild = [self osBuild];
    newDevice.locale = [self locale:MS_LOCALE];
    newDevice.timeZoneOffset = [self timeZoneOffset:[NSTimeZone localTimeZone]];
    newDevice.screenSize = [self screenSize];
    newDevice.appVersion = [self appVersion:MS_APP_MAIN_BUNDLE];
#if TARGET_OS_IOS
    newDevice.carrierCountry = [self carrierCountry:carrier] ?: overriddenCountryCode;
    newDevice.carrierName = [self carrierName:carrier];
#else

    // Carrier information is not available on macOS/tvOS, but if we have an override country code, use it.
    newDevice.carrierCountry = overriddenCountryCode;
    newDevice.carrierName = nil;
#endif
    newDevice.appBuild = [self appBuild:MS_APP_MAIN_BUNDLE];
    newDevice.appNamespace = [self appNamespace:MS_APP_MAIN_BUNDLE];

    // Add wrapper SDK information
    [self refreshWrapperSdk:newDevice];

    // Make sure we set the flag to indicate we don't need to update our device info.
    needRefresh = NO;

    // Return new device.
    return newDevice;
  }
}

/**
 *  Refresh wrapper SDK properties.
 */
- (void)refreshWrapperSdk:(MSDevice *)device {
  if (wrapperSdkInformation) {
    device.wrapperSdkVersion = wrapperSdkInformation.wrapperSdkVersion;
    device.wrapperSdkName = wrapperSdkInformation.wrapperSdkName;
    device.wrapperRuntimeVersion = wrapperSdkInformation.wrapperRuntimeVersion;
    device.liveUpdateReleaseLabel = wrapperSdkInformation.liveUpdateReleaseLabel;
    device.liveUpdateDeploymentKey = wrapperSdkInformation.liveUpdateDeploymentKey;
    device.liveUpdatePackageHash = wrapperSdkInformation.liveUpdatePackageHash;
  }
}

- (MSDevice *)deviceForTimestamp:(NSDate *)timestamp {
  if (!timestamp || self.deviceHistory.count == 0) {

    // Return a new device in case we don't have a device in our history or timestamp is nil.
    return [self device];
  } else {

    // This implements a binary search with complexity O(log n).
    MSDeviceHistoryInfo *find = [[MSDeviceHistoryInfo alloc] initWithTimestamp:timestamp andDevice:nil];
    NSUInteger index = [self.deviceHistory indexOfObject:find
                                           inSortedRange:NSMakeRange(0, self.deviceHistory.count)
                                                 options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
                                         usingComparator:^(MSDeviceHistoryInfo *a, MSDeviceHistoryInfo *b) {
                                           return [a.timestamp compare:b.timestamp];
                                         }];

    /*
     * All timestamps are larger.
     * For now, the SDK picks up the oldest which is closer to the device info at the crash time.
     */
    if (index == 0) {
      return self.deviceHistory[0].device;
    }

    // All timestamps are smaller.
    else if (index == self.deviceHistory.count) {
      return [self.deviceHistory lastObject].device;
    }

    // [index - 1] should be the right index for the timestamp.
    else {
      return self.deviceHistory[index - 1].device;
    }
  }
}

- (void)clearDevices {
  @synchronized(self) {

    // Clear information about the entire history, except for the current device.
    if (self.deviceHistory.count > 1) {
      [self.deviceHistory removeObjectsInRange:NSMakeRange(0, self.deviceHistory.count - 1)];
    }

    // Clear persistence, but keep the latest information about the device.
    [MS_APP_CENTER_USER_DEFAULTS setObject:[MSUtility archiveKeyedData:self.deviceHistory] forKey:kMSPastDevicesKey];
  }
}

#pragma mark - Helpers

- (NSString *)deviceModel {
  size_t size;
#if TARGET_OS_OSX || TARGET_OS_MACCATALYST
  const char *name = "hw.model";
#else
  const char *name = "hw.machine";
#endif
  sysctlbyname(name, NULL, &size, NULL, 0);
  char *answer = (char *)malloc(size);
  if (answer == NULL) {
    return nil;
  }
  sysctlbyname(name, answer, &size, NULL, 0);
  NSString *model = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
  free(answer);
  return model;
}

#if TARGET_OS_OSX || TARGET_OS_MACCATALYST
- (NSString *)osName {
  return @"macOS";
}
#else
- (NSString *)osName:(UIDevice *)device {
  return device.systemName;
}
#endif

#if TARGET_OS_OSX
- (NSString *)osVersion {
  NSString *osVersion = nil;

  if (@available(macOS 10.10, *)) {
    NSOperatingSystemVersion osSystemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    osVersion = [NSString stringWithFormat:@"%ld.%ld.%ld", (long)osSystemVersion.majorVersion, (long)osSystemVersion.minorVersion,
                                           (long)osSystemVersion.patchVersion];
  } else {
    SInt32 major, minor, bugfix;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    OSErr err1 = Gestalt(gestaltSystemVersionMajor, &major);
    OSErr err2 = Gestalt(gestaltSystemVersionMinor, &minor);
    OSErr err3 = Gestalt(gestaltSystemVersionBugFix, &bugfix);
    if ((!err1) && (!err2) && (!err3)) {
      osVersion = [NSString stringWithFormat:@"%ld.%ld.%ld", (long)major, (long)minor, (long)bugfix];
    }
#pragma clang diagnostic pop
  }
  return osVersion;
}
#else
- (NSString *)osVersion:(UIDevice *)device {
  return device.systemVersion;
}
#endif

- (NSString *)osBuild {
  size_t size;
  sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
  char *answer = (char *)malloc(size);
  if (answer == NULL) {
    return nil;
  }
  sysctlbyname("kern.osversion", answer, &size, NULL, 0);
  NSString *osBuild = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
  free(answer);
  return osBuild;
}

- (NSString *)locale:(NSLocale *)currentLocale {

  /*
   * [currentLocale objectForKey:NSLocaleIdentifier] will return an alternate language if a language set in system is not supported by
   * applications. If system language is set to en_US but an application doesn't support en_US, for example, the OS will return the next
   * application supported language in Preferred Language Order list unless there is only one language in the list. The method will return
   * the first language in the list to prevent from the above scenario.
   *
   * In addition to that:
   * 1. preferred language returns "-" instead of "_" as a delimiter of language code and country code, the method will concatenate language
   * code and country code with "_" and return it.
   * 2. some languages can be set without country code so region code can be returned in this case.
   * 3. some langugaes have script code which differentiate languages. E.g. zh-Hans and zh-Hant. This is a possible scenario in Apple
   * platforms that a locale can be zh_CN for Traditional Chinese. The method will return zh-Hant_CN in this case to make sure system
   * language is Traditional Chinese even though region is set to China.
   */
  NSLocale *preferredLanguage = [[NSLocale alloc] initWithLocaleIdentifier:[NSLocale preferredLanguages][0]];
  NSString *languageCode = [preferredLanguage objectForKey:NSLocaleLanguageCode];
  NSString *scriptCode = [preferredLanguage objectForKey:NSLocaleScriptCode];
  NSString *countryCode = [preferredLanguage objectForKey:NSLocaleCountryCode];
  NSString *locale =
      [NSString stringWithFormat:@"%@%@_%@", languageCode, (scriptCode ? [NSString stringWithFormat:@"-%@", scriptCode] : @""),
                                 countryCode ?: [currentLocale objectForKey:NSLocaleCountryCode]];
  return locale;
}

- (NSNumber *)timeZoneOffset:(NSTimeZone *)timeZone {
  return @([timeZone secondsFromGMT] / 60);
}

- (NSString *)screenSize {
#if TARGET_OS_OSX

  // Report screen resolution as shown in display settings ('Looks like' field in scaling tab).
  NSSize screenSize = [NSScreen mainScreen].frame.size;
  return [NSString stringWithFormat:@"%dx%d", (int)screenSize.width, (int)screenSize.height];
#elif TARGET_OS_MACCATALYST

  // macOS API is not directly avaliable on Mac Catalyst.
  NSObject *screen = [NSClassFromString(@"NSScreen") valueForKey:@"mainScreen"];
  if (screen == nil) {
    CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
    return [NSString stringWithFormat:@"%dx%d", (int)screenSize.width, (int)screenSize.height];
  }
  SEL selector = NSSelectorFromString(@"frame");
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[screen class] instanceMethodSignatureForSelector:selector]];
  [invocation setSelector:selector];
  [invocation setTarget:screen];
  [invocation invoke];
  CGRect frame;
  [invocation getReturnValue:&frame];
  return [NSString stringWithFormat:@"%dx%d", (int)frame.size.width, (int)frame.size.height];
#else
  CGFloat scale = [UIScreen mainScreen].scale;
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  return [NSString stringWithFormat:@"%dx%d", (int)(screenSize.height * scale), (int)(screenSize.width * scale)];
#endif
}

#if TARGET_OS_IOS
- (NSString *)carrierName:(CTCarrier *)carrier {
  return [self isValidCarrierName:carrier.carrierName] ? carrier.carrierName : nil;
}

- (NSString *)carrierCountry:(CTCarrier *)carrier {
  return ([carrier.isoCountryCode length] > 0) ? carrier.isoCountryCode : nil;
}

- (BOOL)isValidCarrierName:(NSString *)carrier {
  return [carrier length] > 0 && [@"carrier" caseInsensitiveCompare:carrier] != NSOrderedSame;
}

- (CTCarrier *)firstCarrier:(NSDictionary<NSString *, CTCarrier *> *)carriers {
  for (NSString *key in carriers) {
    return carriers[key];
  }
  return nil;
}
#endif

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
