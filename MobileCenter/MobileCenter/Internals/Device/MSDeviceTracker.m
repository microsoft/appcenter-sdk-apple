#import "MSConstants+Internal.h"
#import "MSDeviceHistoryInfo.h"
#import "MSDeviceTracker.h"
#import "MSDeviceTrackerPrivate.h"
#import "MSUtil.h"
#import "MSDevicePrivate.h"
#import "MSWrapperSdkPrivate.h"
#import "MSUserDefaults.h"

// SDK versioning struct. Needs to be big enough to hold the info.
typedef struct {
  uint8_t info_version;
  const char ms_name[32];
  const char ms_version[32];
  const char ms_build[32];
} ms_info_t;

// SDK versioning.
ms_info_t mobilecenter_library_info
    __attribute__((section("__TEXT,__ms_ios,regular,no_dead_strip"))) = {.info_version = 1,
                                                                         .ms_name = MOBILE_CENTER_C_NAME,
                                                                         .ms_version = MOBILE_CENTER_C_VERSION,
                                                                         .ms_build = MOBILE_CENTER_C_BUILD};

static NSString *const kMSPastDevicesKey = @"pastDevicesKey";
static NSUInteger const kMSMaxDevicesHistoryCount = 5;

@interface MSDeviceTracker ()

// We need a private setter for the device to avoid the warning that is related to direct access of ivars.
@property(nonatomic) MSDevice *device;

@end

@implementation MSDeviceTracker : NSObject

static BOOL needRefresh = YES;
static MSWrapperSdk *wrapperSdkInformation = nil;

- (instancetype)init {
  if (self = [super init]) {

    // Restore past sessions from NSUserDefaults.
    NSData *devices = [MS_USER_DEFAULTS objectForKey:kMSPastDevicesKey];
    if (devices != nil) {
      NSArray *arrayFromData = [NSKeyedUnarchiver unarchiveObjectWithData:devices];

      // If array is not nil, create a mutable version.
      if (arrayFromData)
        _deviceHistory = [NSMutableArray arrayWithArray:arrayFromData];
    }

    // Create new array and creade device info in case we don't have any from disk.
    if (_deviceHistory == nil) {
      _deviceHistory = [NSMutableArray<MSDeviceHistoryInfo *> new];
      
      // Don't assign the new device to the property to continue using lazy initialization later.
      // We're creating this one to have a history.
      [self device];
    }
    
    _device = [self device];
  }
  return self;
}

+ (void)setWrapperSdk:(MSWrapperSdk *)wrapperSdk {
  @synchronized(self) {
    wrapperSdkInformation = wrapperSdk;
    needRefresh = YES;
  }
}

+ (void)setNeedsRefresh:(BOOL)needsRefresh {
  @synchronized (self) {
    needRefresh = needsRefresh;
  }
}

+ (BOOL)needsRefresh {
  return needRefresh;
}

/**
 *  Get the current device log.
 */
- (MSDevice *)device {
  @synchronized(self) {

    // Lazy creation.
    if (!_device || needRefresh) {

      // Get new device info.
      _device = [self updatedDevice];

      // Create new MSDeviceHistoryInfo.
      NSNumber *tOffset = [NSNumber numberWithLongLong:[MSUtil nowInMilliseconds]];
      MSDeviceHistoryInfo *deviceHistoryInfo = [[MSDeviceHistoryInfo alloc] initWithTOffset:tOffset andDevice:_device];

      // Insert at the beginning of the list.
      //      [self.deviceHistory insertObject:deviceHistoryInfo atIndex:0];

      // Insert new MSDeviceHistoryInfo at the proper index to keep self.deviceHistory sorted.
      NSUInteger newIndex = [self.deviceHistory indexOfObject:deviceHistoryInfo
          inSortedRange:(NSRange) { 0, [self.deviceHistory count] }
          options:NSBinarySearchingInsertionIndex
          usingComparator:^(id a, id b) {
            return [((MSDeviceHistoryInfo *)a).tOffset compare:((MSDeviceHistoryInfo *)b).tOffset];
          }];
      [self.deviceHistory insertObject:deviceHistoryInfo atIndex:newIndex];

      // Remove first (the oldest) item if reached max limit.
      if ([self.deviceHistory count] > kMSMaxDevicesHistoryCount) {
        [self.deviceHistory removeObjectAtIndex:0];
      }

      // Persist the device history in NSData format.
      [MS_USER_DEFAULTS setObject:[NSKeyedArchiver archivedDataWithRootObject:self.deviceHistory]
                           forKey:kMSPastDevicesKey];
    }
    return _device;
  }
}

/**
 *  Refresh device properties.
 */
- (MSDevice *)updatedDevice {
  @synchronized(self) {
    MSDevice *newDevice = [[MSDevice alloc] init];
    NSBundle *appBundle = [NSBundle mainBundle];
    CTCarrier *carrier = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];

    // Collect device properties.
    newDevice.sdkName = [self sdkName:mobilecenter_library_info.ms_name];
    newDevice.sdkVersion = [self sdkVersion:mobilecenter_library_info.ms_version];
    newDevice.model = [self deviceModel];
    newDevice.oemName = kMSDeviceManufacturer;
    newDevice.osName = [self osName:MS_DEVICE];
    newDevice.osVersion = [self osVersion:MS_DEVICE];
    newDevice.osBuild = [self osBuild];
    newDevice.locale = [self locale:MS_LOCALE];
    newDevice.timeZoneOffset = [self timeZoneOffset:[NSTimeZone localTimeZone]];
    newDevice.screenSize = [self screenSize];
    newDevice.appVersion = [self appVersion:appBundle];
    newDevice.carrierCountry = [self carrierCountry:carrier];
    newDevice.carrierName = [self carrierName:carrier];
    newDevice.appBuild = [self appBuild:appBundle];
    newDevice.appNamespace = [self appNamespace:appBundle];

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
    device.liveUpdateReleaseLabel = wrapperSdkInformation.liveUpdateReleaseLabel;
    device.liveUpdateDeploymentKey = wrapperSdkInformation.liveUpdateDeploymentKey;
    device.liveUpdatePackageHash = wrapperSdkInformation.liveUpdatePackageHash;
  }
}

- (MSDevice *)deviceForToffset:(NSNumber *)tOffset {
  if (!tOffset || self.deviceHistory.count == 0) {
//    __block MSDevice *device;
//    [self.deviceHistory
//        enumerateObjectsUsingBlock:^(MSDeviceHistoryInfo *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
//          if ([tOffset compare:obj.tOffset] == NSOrderedDescending) {
//            device = obj.device;
//            *stop = YES;
//          }
//        }];
//    return device;
    return [self device];
  } else {
    MSDeviceHistoryInfo *find = [[MSDeviceHistoryInfo alloc] initWithTOffset:tOffset andDevice:nil];
    NSUInteger index = [self.deviceHistory indexOfObject:find
                                         inSortedRange:NSMakeRange(0, self.deviceHistory.count)
                                               options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex
                                       usingComparator:^(id a, id b) {
                                         return [((MSDeviceHistoryInfo *)a).tOffset compare:((MSDeviceHistoryInfo *)b).tOffset];
                                       }];
    
    // all numbers are larger than search
    if (index == 0) {
      NSLog(@"all numbers are larger than search, found %@", self.deviceHistory[0]);
      return self.deviceHistory[0].device;
    }
    
    // all numbers are smaller than search
    else if (index == self.deviceHistory.count) {
      NSLog(@"all numbers are smaller than search, found %@", [self.deviceHistory lastObject]);
      return [self.deviceHistory lastObject].device;
    }
    else {
      // our array contains SEARCH or we pick the smallest delta
      long long leftDifference = [tOffset longLongValue] - [self.deviceHistory[index - 1].tOffset longLongValue];
      long long rightDifference = [self.deviceHistory[index].tOffset longLongValue] - [tOffset longLongValue];
      if (leftDifference < rightDifference) {
        --index;
        
      }
      NSLog(@"equal value or closest match, found %@", self.deviceHistory[index]);
      return self.deviceHistory[index].device;
    }
  }
}

- (void)clearDevices {
  @synchronized(self) {
    
    // Clear persistence.
    [MS_USER_DEFAULTS removeObjectForKey:kMSPastDevicesKey];
    
    // Clear cache.
    self.device = nil;
    [self.deviceHistory removeAllObjects];
  }
}


#pragma mark - Helpers

- (NSString *)sdkName:(const char[])name {
  return [NSString stringWithUTF8String:name];
}

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

- (NSString *)osBuild {
  size_t size;
  sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
  char *answer = (char *)malloc(size);
  if (answer == NULL)
    return nil; // returning nil to avoid a possible crash.
  sysctlbyname("kern.osversion", answer, &size, NULL, 0);
  NSString *osBuild = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
  free(answer);
  return osBuild;
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
