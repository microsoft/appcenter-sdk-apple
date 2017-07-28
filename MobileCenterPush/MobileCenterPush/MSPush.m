#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UserNotifications/UserNotifications.h>
#import "MSAppDelegateForwarder.h"
#import "MSPushAppDelegate.h"
#endif

#import "MSMobileCenterInternal.h"
#import "MSPush.h"
#import "MSPushLog.h"
#import "MSPushNotificationInternal.h"
#import "MSPushPrivate.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"Push";

/**
 * The group ID for storage.
 */
static NSString *const kMSGroupId = @"Push";

/**
 * Key for storing push token
 */
static NSString *const kMSPushServiceStorageKey = @"pushServiceStorageKey";

/**
 * Keys for payload in push notification.
 */
static NSString *const kMSPushNotificationApsKey = @"aps";
static NSString *const kMSPushNotificationAlertKey = @"alert";
static NSString *const kMSPushNotificationTitleKey = @"title";
static NSString *const kMSPushNotificationMessageKey = @"body";
static NSString *const kMSPushNotificationCustomDataKey = @"mobile_center";

/**
 * Singleton
 */
static MSPush *sharedInstance = nil;
static dispatch_once_t onceToken;

@implementation MSPush

@synthesize channelConfiguration = _channelConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {

    // Init channel configuration.
    _channelConfiguration = [[MSChannelConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];
// TODO: Implement macOS
#if !TARGET_OS_OSX
    _appDelegate = [MSPushAppDelegate new];
#endif
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
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

+ (NSString *)logTag {
  return @"MobileCenterPush";
}

- (NSString *)groupId {
  return kMSGroupId;
}

#pragma mark - MSPush

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  [[self sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  [[self sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
}

#if TARGET_OS_OSX
+ (BOOL)didReceiveNotification:(NSNotification *)notification {
  return [[self sharedInstance] didReceiveNotification:notification];
}

#else
+ (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo {
  return [[self sharedInstance] didReceiveRemoteNotification:userInfo];
}
#endif

+ (void)setDelegate:(nullable id<MSPushDelegate>)delegate {
  [[self sharedInstance] setDelegate:delegate];
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {
// TODO: Implement macOS
#if !TARGET_OS_OSX
    [MSAppDelegateForwarder addDelegate:self.appDelegate];
#endif
    if (!self.pushTokenHasBeenSent) {
      [self registerForRemoteNotifications];
    }
    MSLogInfo([MSPush logTag], @"Push service has been enabled.");
  } else {
// TODO: Implement macOS
#if !TARGET_OS_OSX
    [MSAppDelegateForwarder removeDelegate:self.appDelegate];
#endif
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

#if TARGET_OS_OSX
  [NSApp registerForRemoteNotificationTypes:(NSRemoteNotificationTypeAlert | NSRemoteNotificationTypeSound |
                                             NSRemoteNotificationTypeBadge)];
#elif TARGET_OS_IOS
  if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
    UIUserNotificationType allNotificationTypes = (UIUserNotificationType)(
        UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
    UIUserNotificationSettings *settings =
        [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
  } else {

// Ignore the partial availability warning as the compiler doesn't get that we checked for pre-iOS 10 already.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions authOptions =
        (UNAuthorizationOptions)(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge);
    [center requestAuthorizationWithOptions:authOptions
                          completionHandler:^(__attribute__((unused)) BOOL granted,
                                              __attribute__((unused)) NSError *_Nullable error){
                          }];
#pragma clang diagnostic pop
  }
  [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
}

// TODO: Implement macOS
#if !TARGET_OS_OSX
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

- (void)sendPushToken:(NSString *)token {
  MSPushLog *log = [MSPushLog new];
  log.pushToken = token;
  [self.logManager processLog:log forGroupId:self.groupId];
  self.pushTokenHasBeenSent = YES;
}

#pragma mark - Register callbacks

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  MSLogVerbose([MSPush logTag], @"Registering for push notifications has been finished successfully");
  NSString *strPushToken = [self convertTokenToString:deviceToken];
  [MS_USER_DEFAULTS setObject:strPushToken forKey:kMSPushServiceStorageKey];
  [self sendPushToken:strPushToken];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  MSLogVerbose([MSPush logTag], @"Registering for push notifications has been finished with error: %@",
               error.description);
}

// TODO: Review this method name.
#if TARGET_OS_OSX
- (BOOL)didReceiveNotification:(NSNotification *)notification {
  NSUserNotification *userNotification;

  /*
   * If the notification is from didActivateNotification, the notification type is NSUserNotification. Otherwise,
   * NSUserNotification will be placed in NSNotification.userInfo.
   */
  if ([notification isKindOfClass:[NSUserNotification class]]) {
    userNotification = (NSUserNotification *)notification;
  } else {
    userNotification = [notification.userInfo objectForKey:NSApplicationLaunchUserNotificationKey];
  }
  if (userNotification && [self didReceiveRemoteNotification:userNotification.userInfo]) {
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];

    // The delivered notification should be removed.
    [center removeDeliveredNotification:userNotification];
    return YES;
  }
  return NO;
}
#endif

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo {
  MSLogVerbose([MSPush logTag], @"User info for notification has forwarded to Push: %@", [userInfo description]);
  NSString *title;
  NSString *message;
  NSDictionary *aps = [userInfo objectForKey:kMSPushNotificationApsKey];
  NSObject *alert = [aps objectForKey:kMSPushNotificationAlertKey];
  if ([alert isKindOfClass:[NSDictionary class]]) {
    title = [alert valueForKey:kMSPushNotificationTitleKey];
    message = [alert valueForKey:kMSPushNotificationMessageKey];
  } else {

    // "alert" value can be either Dictionary or String. Try one more if it is a String value.
    alert = [aps valueForKey:kMSPushNotificationAlertKey];
    if ([alert isKindOfClass:[NSString class]]) {
      title = @"";
      message = (NSString *)alert;
    } else {

      // "alert" value is not a supported type.
      return NO;
    }
  }

  // The notification is not for Mobile Center if customData is nil. Ignore the notification.
  NSDictionary *customData = [userInfo objectForKey:kMSPushNotificationCustomDataKey];
  if (customData) {
    MSLogDebug([MSPush logTag], @"Notification received.\nTitle: %@\nMessage:%@\nCustom data: %@", title, message,
               [customData description]);

    // Initialize push notification model.
    MSPushNotification *pushNotification =
        [[MSPushNotification alloc] initWithTitle:title message:message customData:customData];

    // Call push delegate and deliver notification back to the application.
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate push:self didReceivePushNotification:pushNotification];
    });
    return YES;
  }
  return NO;
}

@end
