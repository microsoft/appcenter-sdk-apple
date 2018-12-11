#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <IOKit/IOKitLib.h>
#else
#import <UIKit/UIKit.h>
#endif

#import "MSAnalyticsInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSAppExtension.h"
#import "MSCSExtensions.h"
#import "MSCommonSchemaLog.h"
#import "MSConstants+Internal.h"
#import "MSDeviceExtension.h"
#import "MSEventPropertiesInternal.h"
#import "MSLogger.h"
#import "MSPropertyConfiguratorPrivate.h"
#import "MSStringTypedProperty.h"
#import "MSUserExtension.h"
#import "MSUserIdContext.h"

@implementation MSPropertyConfigurator

#if TARGET_OS_OSX
static const char deviceIdPrefix = 'u';
#else
static const char deviceIdPrefix = 'i';
#endif

- (instancetype)initWithTransmissionTarget:(MSAnalyticsTransmissionTarget *)transmissionTarget {
  if ((self = [super init])) {
    _transmissionTarget = transmissionTarget;
    _eventProperties = [MSEventProperties new];
  }
  return self;
}

- (void)setAppVersion:(NSString *)appVersion {
  _appVersion = appVersion;
}

- (void)setAppName:(NSString *)appName {
  _appName = appName;
}

- (void)setAppLocale:(NSString *)appLocale {
  _appLocale = appLocale;
}

- (void)setUserId:(NSString *)userId {
  if ([MSUserIdContext isUserIdValidForOneCollector:userId]) {
    NSString *prefixedUserId = [MSUserIdContext prefixedUserIdFromUserId:userId];
    _userId = prefixedUserId;
  }
}

- (void)setEventPropertyString:(NSString *)propertyValue forKey:(NSString *)propertyKey {
  @synchronized([MSAnalytics sharedInstance]) {
    [self.eventProperties setString:propertyValue forKey:propertyKey];
  }
}

- (void)setEventPropertyDouble:(double)propertyValue forKey:(NSString *)propertyKey {
  @synchronized([MSAnalytics sharedInstance]) {
    [self.eventProperties setDouble:propertyValue forKey:propertyKey];
  }
}

- (void)setEventPropertyInt64:(int64_t)propertyValue forKey:(NSString *)propertyKey {
  @synchronized([MSAnalytics sharedInstance]) {
    [self.eventProperties setInt64:propertyValue forKey:propertyKey];
  }
}

- (void)setEventPropertyBool:(BOOL)propertyValue forKey:(NSString *)propertyKey {
  @synchronized([MSAnalytics sharedInstance]) {
    [self.eventProperties setBool:propertyValue forKey:propertyKey];
  }
}

- (void)setEventPropertyDate:(NSDate *)propertyValue forKey:(NSString *)propertyKey {
  @synchronized([MSAnalytics sharedInstance]) {
    [self.eventProperties setDate:propertyValue forKey:propertyKey];
  }
}

- (void)removeEventPropertyForKey:(NSString *)propertyKey {
  @synchronized([MSAnalytics sharedInstance]) {
    if (!propertyKey) {
      MSLogError([MSAnalytics logTag], @"Event property key to remove cannot be nil.");
      return;
    }
    [self.eventProperties.properties removeObjectForKey:propertyKey];
  }
}

- (void)collectDeviceId {
  self.deviceId = [MSPropertyConfigurator getDeviceIdentifier];
}

#pragma mark - MSChannelDelegate

- (void)channel:(id<MSChannelProtocol>)__unused channel prepareLog:(id<MSLog>)log {
  MSAnalyticsTransmissionTarget *target = self.transmissionTarget;
  if (target && [log isKindOfClass:[MSCommonSchemaLog class]] && [target isEnabled] && [log.tag isEqual:target]) {

    // Override the application version.
    while (target) {
      if (target.propertyConfigurator.appVersion) {
        ((MSCommonSchemaLog *)log).ext.appExt.ver = target.propertyConfigurator.appVersion;
        break;
      }
      target = target.parentTarget;
    }

    // Override the application name.
    target = self.transmissionTarget;
    while (target) {
      if (target.propertyConfigurator.appName) {
        ((MSCommonSchemaLog *)log).ext.appExt.name = target.propertyConfigurator.appName;
        break;
      }
      target = target.parentTarget;
    }

    // Override the application locale.
    target = self.transmissionTarget;
    while (target) {
      if (target.propertyConfigurator.appLocale) {
        ((MSCommonSchemaLog *)log).ext.appExt.locale = target.propertyConfigurator.appLocale;
        break;
      }
      target = target.parentTarget;
    }

    // Override the userId.
    target = self.transmissionTarget;
    while (target) {
      if (target.propertyConfigurator.userId) {
        ((MSCommonSchemaLog *)log).ext.userExt.localId = target.propertyConfigurator.userId;
        break;
      }
      target = target.parentTarget;
    }

    // The device ID must not be inherited from parent transmission targets.
    [((MSCommonSchemaLog *)log) ext].deviceExt.localId = self.deviceId;
  }
}

#pragma mark - Helper methods

+ (NSString *)getDeviceIdentifier {
  NSString *baseIdentifier;
#if TARGET_OS_OSX
  /*
   * TODO: Uncomment this for macOS support.
   * io_service_t platformExpert = IOServiceGetMatchingService(
   *    kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
   * CFStringRef platformUUIDAsCFString = NULL;
   * if (platformExpert) {
   *  platformUUIDAsCFString = (CFStringRef)IORegistryEntryCreateCFProperty(
   *      platformExpert, CFSTR(kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
   *  IOObjectRelease(platformExpert);
   * }
   * NSString *platformUUIDAsNSString = nil;
   * if (platformUUIDAsCFString) {
   *   platformUUIDAsNSString =
   *    [NSString stringWithString:(__bridge NSString *)platformUUIDAsCFString];
   *   CFRelease(platformUUIDAsCFString);
   * }
   * baseIdentifier = platformUUIDAsNSString;
   */
  baseIdentifier = @"";
#else
  baseIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif
  return [NSString stringWithFormat:@"%c:%@", deviceIdPrefix, baseIdentifier];
}

- (void)mergeTypedPropertiesWith:(MSEventProperties *)mergedEventProperties {
  @synchronized([MSAnalytics sharedInstance]) {
    for (NSString *key in self.eventProperties.properties) {
      if (!mergedEventProperties.properties[key]) {
        mergedEventProperties.properties[key] = self.eventProperties.properties[key];
      }
    }
  }
}

@end
