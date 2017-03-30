#import <UserNotifications/UserNotifications.h>
#import "MSMobileCenterInternal.h"
#import "MSPush.h"
#import "MSPushInternal.h"
#import "MSPushLog.h"
#import "MSPushPrivate.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Push";

/**
 * The group ID for storage.
 */
static NSString *const kMSGroupID = @"Push";

/**
 * Key for storing push token
 */
static NSString *const kMSPushServiceStorageKey = @"pushServiceStorageKey";

/**
 * Singleton
 */
static MSPush *sharedInstance = nil;
static dispatch_once_t onceToken;

@implementation MSPush

@synthesize deviceTokenHasBeenSent;

#pragma mark - Service initialization

- (instancetype)init {
  self = [super init];
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
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

+ (NSString *)logTag {
  return @"MobileCenterPush";
}

- (NSString *)groupID {
  return kMSGroupID;
}

- (MSPriority)priority {
  return MSPriorityDefault;
}

#pragma mark - MSPush

+ (void)didRegisterForRemoteNotificationsWith:(NSData *)deviceToken {
  [[self sharedInstance] didRegisterForRemoteNotificationsWith:deviceToken];
}

+ (void)didFailToRegisterForRemoteNotificationsWith:(NSError *)error {
  [[self sharedInstance] didFailToRegisterForRemoteNotificationsWith:error];
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {
    MSLogInfo([MSPush logTag], @"Push service has been enabled.");
    if (!self.deviceTokenHasBeenSent) {
      [self registerForRemoteNotifications];
    }
  } else {
    MSLogInfo([MSPush logTag], @"Push service has been disabled.");
  }
}

#pragma mark - Private methods

+ (void)resetSharedInstance {

  // Resets the once_token so dispatch_once will run again
  onceToken = 0;
  sharedInstance = nil;
}

- (void)registerForRemoteNotifications {
  MSLogVerbose([MSPush logTag], @"Registering for push notifications");
#if !(TARGET_OS_SIMULATOR)
  if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
    UIUserNotificationType allNotificationTypes = (UIUserNotificationType)(
        UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
    UIUserNotificationSettings *settings =
        [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
  } else {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions authOptions =
        (UNAuthorizationOptions)(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge);
    [center requestAuthorizationWithOptions:authOptions
                          completionHandler:^(__attribute__((unused)) BOOL granted,
                                              __attribute__((unused)) NSError *_Nullable error){
                          }];
  }
  [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
}

#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
  (void)notificationSettings;

  // register to receive notifications
  [application registerForRemoteNotifications];
}
#endif

- (NSString *)convertTokenToString:(NSData *)token {
  if (!token)
    return nil;
  const unsigned char *dataBuffer = token.bytes;
  NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:(token.length * 2)];
  for (NSUInteger i = 0; i < token.length; ++i) {
    [stringBuffer appendFormat:@"%02x", dataBuffer[i]];
  }
  return [NSString stringWithString:stringBuffer];
}

- (void)sendDeviceToken:(NSString *)token {
  MSPushLog *log = [MSPushLog new];
  log.deviceToken = token;
  [self.logManager processLog:log withPriority:self.priority andGroupID:self.groupID];
  self.deviceTokenHasBeenSent = YES;
}

#pragma mark - MSChannelDelegate

- (void)channel:(id<MSChannel>)channel willSendLog:(id<MSLog>)log {
  (void)channel;
  if (!self.delegate) {
    return;
  }
  NSObject *logObject = (NSObject *)log;
  if (![logObject isKindOfClass:[MSPushLog class]] ||
      ![self.delegate respondsToSelector:@selector(push:willSendInstallationLog:)]) {
    return;
  }
  MSPushLog *installationLog = (MSPushLog *)log;
  [self.delegate push:self willSendInstallationLog:installationLog];
}

- (void)channel:(id<MSChannel>)channel didSucceedSendingLog:(id<MSLog>)log {
  (void)channel;
  if (!self.delegate) {
    return;
  }
  NSObject *logObject = (NSObject *)log;
  if (![logObject isKindOfClass:[MSPushLog class]] ||
      ![self.delegate respondsToSelector:@selector(push:didSucceedSendingInstallationLog:)]) {
    return;
  }
  MSPushLog *installationLog = (MSPushLog *)log;
  [self.delegate push:self didSucceedSendingInstallationLog:installationLog];
}

- (void)channel:(id<MSChannel>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  (void)channel;
  if (!self.delegate) {
    return;
  }
  NSObject *logObject = (NSObject *)log;
  if (![logObject isKindOfClass:[MSPushLog class]] ||
      ![self.delegate respondsToSelector:@selector(push:didFailSendingInstallLog:withError:)]) {
    return;
  }
  MSPushLog *installationLog = (MSPushLog *)log;
  [self.delegate push:self didFailSendingInstallLog:installationLog withError:error];
}

#pragma mark - Register callbacks

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  (void)application;
  MSLogVerbose([MSPush logTag], @"Registering for push notifications has been finished successfully");
  NSString *strDeviceToken = [self convertTokenToString:deviceToken];
  [MS_USER_DEFAULTS setObject:strDeviceToken forKey:kMSPushServiceStorageKey];
  [self sendDeviceToken:strDeviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  (void)application;
  MSLogVerbose([MSPush logTag], @"Registering for push notifications has been finished with error: %@",
               error.description);
}

#pragma mark - Delegate

+ (void)setDelegate:(nullable id<MSPushDelegate>)delegate {
  [[self sharedInstance] setDelegate:delegate];
}

@end
