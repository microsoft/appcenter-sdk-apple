#import "MSPush.h"
#import "MSPushPrivate.h"
#import "MSPushInternal.h"
#import "MSDeviceTracker.h"
#import "MSPushInstallationLog.h"
#import "MSMobileCenterInternal.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Push";

/**
 * Key for storing push token
 */
static NSString *const kMSPushServiceStorageKey = @"kmspushservicepushstoringkey";

/**
 * Singleton
 */
static MSPush *sharedInstance = nil;
static dispatch_once_t onceToken;

@implementation MSPush

#pragma mark - Service initialization

- (instancetype)init {

  self = [super init];

  if (self) {

  }

  return self;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [self new];
    }
  });
  return sharedInstance;
}

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];

  MSLogVerbose([MSPush logTag], @"Started push service.");

  [self registerPush];
}

+ (NSString *)logTag {
  return @"MobileCenterPush";
}

- (NSString *)storageKey {
  return kMSServiceName;
}

- (MSPriority)priority {
  return MSPriorityDefault;
}

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityDefault;
}

#pragma mark - MSPush

+ (void)registerPush {
  [[self sharedInstance] registerPush];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  [[self sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  [[self sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {

    MSLogInfo([MSPush logTag], @"Push service has been enabled.");
  } else {

    MSLogInfo([MSPush logTag], @"Push service has been disabled.");
  }
}

#pragma mark - Private methods

- (BOOL)validateProperties:(NSDictionary<NSString *, NSString *> *)properties {
  for (id key in properties) {
    if (![key isKindOfClass:[NSString class]] || ![[properties objectForKey:key] isKindOfClass:[NSString class]]) {
      return NO;
    }
  }
  return YES;
}

+ (void)resetSharedInstance {

  // resets the once_token so dispatch_once will run again
  onceToken = 0;
  sharedInstance = nil;
}

- (void) registerPush {

  MSLogVerbose([MSPush logTag], @"Registering for push notifications");

  [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (NSString *)getDeviceTokenString:(NSData *)deviceToken {
  if (!deviceToken)
    return nil;

  const unsigned char* dataBuffer = [deviceToken bytes];
  NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:(deviceToken.length * 2)];

  for (NSUInteger i = 0; i < deviceToken.length; ++i) {
    [stringBuffer appendFormat:@"%02x", dataBuffer[i]];
  }

  return [NSString stringWithString:stringBuffer];
}

#pragma mark - MSChannelDelegate

- (void)channel:(id)channel willSendLog:(id<MSLog>)log {
  if (!self.delegate) {
    return;
  }
}

- (void)channel:(id<MSChannel>)channel didSucceedSendingLog:(id<MSLog>)log {
  if (!self.delegate) {
    return;
  }
}

- (void)channel:(id<MSChannel>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  if (!self.delegate) {
    return;
  }
}

#pragma mark - Register callbacks

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

  MSLogVerbose([MSPush logTag], @"Registering for push notifications has been finished successfully");

  MSDevice *device = [MSDeviceTracker alloc].device;
  NSString *strDeviceToken = [self getDeviceTokenString:deviceToken];

  //save key in internal storage
  [MSUserDefaults.shared setObject:strDeviceToken forKey:kMSPushServiceStorageKey];

  //and send it to log
  MSPushInstallationLog *log = [MSPushInstallationLog new];

  log.installationId =  [[MSMobileCenter installId] UUIDString];
  log.pushChannel = strDeviceToken;
  log.tags = @[device.appVersion,
               device.sdkVersion,
               device.osName,
               device.screenSize,
               device.locale,
               device.osVersion,
               device.appBuild];

  [self.logManager processLog:log withPriority:MSPriorityHigh];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {

  MSLogVerbose([MSPush logTag], @"Registering for push notifications has been finished with error: %@", err.description);
}

@end
