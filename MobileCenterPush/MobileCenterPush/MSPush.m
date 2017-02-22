#import "MSPush.h"
#import "MSPushPrivate.h"
#import "MSPushInternal.h"
#import "MSDeviceTracker.h"
#import "MSPushInstallationLog.h"
#import "MSMobileCenterInternal.h"

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

#import <UserNotifications/UserNotifications.h>

#endif

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

@interface MSPush()

@property (nonatomic) BOOL deviceTokenHasBeenSent;
@property BOOL isRequestInProgress;

@end

@implementation MSPush

@synthesize deviceTokenHasBeenSent;
@synthesize isRequestInProgress;

#pragma mark - Service initialization

- (instancetype)init {

  self = [super init];

  if (self) {

    deviceTokenHasBeenSent = NO;
    isRequestInProgress = NO;
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

  if( [MSPush isEnabled] ) {

    [self registerForRemoteNotifications];
  }
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
  [[self sharedInstance] registerForRemoteNotifications];
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

    if( !self.deviceTokenHasBeenSent ) {

      [self registerForRemoteNotifications];
    }
  } else {

    [[UIApplication sharedApplication] unregisterForRemoteNotifications];

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

- (void) registerForRemoteNotifications {

  if( self.isRequestInProgress )
    return;
  self.isRequestInProgress = YES;

  MSLogVerbose([MSPush logTag], @"Registering for push notifications");

  if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {

    UIUserNotificationType allNotificationTypes = (UIUserNotificationType) (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
  } else {

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    [center requestAuthorizationWithOptions:authOptions
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {}];

    [center setDelegate:[[UIApplication sharedApplication] delegate]];
#endif
  }

  [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (NSString *)convertTokenToString:(NSData *)token {
  
  if (!token)
    return nil;

  const unsigned char* dataBuffer = [token bytes];
  NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:(token.length * 2)];

  for (NSUInteger i = 0; i < token.length; ++i) {
    [stringBuffer appendFormat:@"%02x", dataBuffer[i]];
  }

  return [NSString stringWithString:stringBuffer];
}

- (void) sendDeviceToken: (NSString *)token {

  MSDevice *device = [MSDeviceTracker alloc].device;

  MSPushInstallationLog *log = [MSPushInstallationLog new];

  log.installationId =  [[MSMobileCenter installId] UUIDString];
  log.pushChannel = token;
  log.tags = @[device.appVersion,
               device.sdkVersion,
               device.osName,
               device.screenSize,
               device.locale,
               device.osVersion,
               device.appBuild];

  [self.logManager processLog:log withPriority:MSPriorityHigh];

  self.deviceTokenHasBeenSent = YES;
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

  NSString *strDeviceToken = [self convertTokenToString:deviceToken];
  [MSUserDefaults.shared setObject:strDeviceToken forKey:kMSPushServiceStorageKey];
  [self sendDeviceToken:strDeviceToken];

  self.isRequestInProgress = NO;
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {

  MSLogVerbose([MSPush logTag], @"Registering for push notifications has been finished with error: %@", err.description);

  self.isRequestInProgress = NO;
}

@end
