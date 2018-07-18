#import "MSPropertyConfigurator.h"
#import "MSProperyConfiguratorPrivate.h"

@implementation MSPropertyConfigurator

- (void)setAppName:(NSString *)appName {
  _appName = appName;
}

- (void)setAppVersion:(NSString *)appVersion {
  _appVersion = appVersion;
}

- (void)setAppLocale:(NSString *)appLocale {
  _appLocale = appLocale;
}

#pragama mark - MSChannelDelegate

- (void)channel:(id<MSChannelProtocol>)channel prepareLog:(id<MSLog>)log {
  
}

@end
