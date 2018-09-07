#import "MSPropertyConfiguratorPrivate.h"

#if TARGET_OS_OSX
#import <IOKit/IOKitLib.h>
#else
#import <UIKit/UIKit.h>
#endif

#import "MSAnalyticsInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSCommonSchemaLog.h"
#import "MSLogger.h"

@implementation MSPropertyConfigurator

#if TARGET_OS_OSX
static const char deviceIdPrefix = 'u';
#else
static const char deviceIdPrefix = 'i';
#endif

- (instancetype)initWithTransmissionTarget:
    (MSAnalyticsTransmissionTarget *)transmissionTarget {
  if ((self = [super init])) {
    _transmissionTarget = transmissionTarget;
    _eventProperties = [NSMutableDictionary<NSString *, NSString *> new];
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

- (void)setEventPropertyString:(NSString *)propertyValue
                        forKey:(NSString *)propertyKey {
  @synchronized([MSAnalytics sharedInstance]) {
    if (!propertyValue || !propertyKey) {
      MSLogError([MSAnalytics logTag],
                 @"Event property keys and values cannot be nil.");
      return;
    }
    self.eventProperties[propertyKey] = propertyValue;
  }
}

- (void)removeEventPropertyForKey:(NSString *)propertyKey {
  @synchronized([MSAnalytics sharedInstance]) {
    if (!propertyKey) {
      MSLogError([MSAnalytics logTag],
                 @"Event property key to remove cannot be nil.");
      return;
    }
    [self.eventProperties removeObjectForKey:propertyKey];
  }
}

- (void)collectDeviceId {
  self.deviceId = [MSPropertyConfigurator getDeviceIdentifier];
}

#pragma mark - MSChannelDelegate

- (void)channel:(id<MSChannelProtocol>)__unused channel
     prepareLog:(id<MSLog>)log {
  MSAnalyticsTransmissionTarget *target = self.transmissionTarget;
  if (target && [log isKindOfClass:[MSCommonSchemaLog class]] &&
      [target isEnabled]) {

    // TODO Find a better way to override properties.

    // Only override properties for owned target.
    if (![log.transmissionTargetTokens
            containsObject:target.transmissionTargetToken]) {
      return;
    }

    // Override the application version.
    while (target) {
      if (target.propertyConfigurator.appVersion) {
        ((MSCommonSchemaLog *)log).ext.appExt.ver =
            target.propertyConfigurator.appVersion;
        break;
      }
      target = target.parentTarget;
    }

    // Override the application name.
    target = self.transmissionTarget;
    while (target) {
      if (target.propertyConfigurator.appName) {
        ((MSCommonSchemaLog *)log).ext.appExt.name =
            target.propertyConfigurator.appName;
        break;
      }
      target = target.parentTarget;
    }

    // Override the application locale.
    target = self.transmissionTarget;
    while (target) {
      if (target.propertyConfigurator.appLocale) {
        ((MSCommonSchemaLog *)log).ext.appExt.locale =
            target.propertyConfigurator.appLocale;
        break;
      }
      target = target.parentTarget;
    }

    // The device ID must not be inherited from parent transmission targets.
    [((MSCommonSchemaLog *)log)ext].deviceExt.localId = self.deviceId;
  }
}

#pragma mark - Helper methods

+ (NSString *)getDeviceIdentifier {
  NSString *baseIdentifier;
#if TARGET_OS_OSX
  io_service_t platformExpert = IOServiceGetMatchingService(
      kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
  CFStringRef platformUUIDAsCFString = NULL;
  if (platformExpert) {
    platformUUIDAsCFString = (CFStringRef)IORegistryEntryCreateCFProperty(
        platformExpert, CFSTR(kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
    IOObjectRelease(platformExpert);
  }
  NSString *platformUUIDAsNSString = nil;
  if (platformUUIDAsCFString) {
    platformUUIDAsNSString =
        [NSString stringWithString:(__bridge NSString *)platformUUIDAsCFString];
    CFRelease(platformUUIDAsCFString);
  }
  baseIdentifier = platformUUIDAsNSString;
#else
  baseIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif
  return [NSString stringWithFormat:@"%c:%@", deviceIdPrefix, baseIdentifier];
}

@end
