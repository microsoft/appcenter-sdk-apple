#import "MSPropertyConfigurator.h"
#import "MSAnalyticsInternal.h"
#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsTransmissionTargetPrivate.h"
#import "MSCommonSchemaLog.h"
#import "MSLogger.h"
#import "MSPropertyConfiguratorPrivate.h"

@implementation MSPropertyConfigurator

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
        [((MSCommonSchemaLog *)log)ext].appExt.ver =
            target.propertyConfigurator.appVersion;
        break;
      }
      target = target.parentTarget;
    }

    // Override the application name.
    target = self.transmissionTarget;
    while (target) {
      if (target.propertyConfigurator.appName) {
        [((MSCommonSchemaLog *)log)ext].appExt.name =
            target.propertyConfigurator.appName;
        break;
      }
      target = target.parentTarget;
    }

    // Override the application locale.
    target = self.transmissionTarget;
    while (target) {
      if (target.propertyConfigurator.appLocale) {
        [((MSCommonSchemaLog *)log)ext].appExt.locale =
            target.propertyConfigurator.appLocale;
        break;
      }
      target = target.parentTarget;
    }
  }
}

@end
