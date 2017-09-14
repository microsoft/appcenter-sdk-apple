#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UserNotifications/UserNotifications.h>
#endif

#import "MSAppDelegateForwarder.h"
#import "MSMobileCenterInternal.h"
#import "MSPush.h"
#import "MSPushAppDelegate.h"
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
 * Key for NSUserNotificationCenter delegate property.
 */
static NSString *const kMSUserNotificationCenterDelegateKey = @"delegate";

/**
 * Singleton
 */
static MSPush *sharedInstance = nil;
static dispatch_once_t onceToken;
#if TARGET_OS_OSX
static id<NSUserNotificationCenterDelegate> userNotificationCenterDelegate;
static void *UserNotificationCenterDelegateContext = &UserNotificationCenterDelegateContext;
#endif

@implementation MSPush

@synthesize channelConfiguration = _channelConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {

    // Init channel configuration.
    _channelConfiguration = [[MSChannelConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];
    _appDelegate = [MSPushAppDelegate new];

#if TARGET_OS_OSX
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];

    /*
     * If there is a user notification center delegate already set by a customer before starting Push, assign the
     * delegate to custom user notification center delegate.
     */
    if (center.delegate) {
      userNotificationCenterDelegate = center.delegate;
    }

    // Set a delegate that will forward notifications to Push as well as a customer's delegate.
    center.delegate = self;

    // Observe delegate property changes.
    [center addObserver:self
             forKeyPath:kMSUserNotificationCenterDelegateKey
                options:NSKeyValueObservingOptionNew
                context:UserNotificationCenterDelegateContext];
#endif
  }
  return self;
}

#if TARGET_OS_OSX
- (void)dealloc {
  [[NSUserNotificationCenter defaultUserNotificationCenter] removeObserver:self
                                                                forKeyPath:kMSUserNotificationCenterDelegateKey
                                                                   context:UserNotificationCenterDelegateContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (context == UserNotificationCenterDelegateContext &&
      [keyPath isEqualToString:kMSUserNotificationCenterDelegateKey]) {
    userNotificationCenterDelegate = [change objectForKey:NSKeyValueChangeNewKey];
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center removeObserver:self forKeyPath:keyPath];
    center.delegate = self;
    [center addObserver:self
             forKeyPath:keyPath
                options:NSKeyValueObservingOptionNew
                context:UserNotificationCenterDelegateContext];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

+ (void *)userNotificationCenterDelegateContext {
  return UserNotificationCenterDelegateContext;
}

#endif

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

+ (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo {
  return [[self sharedInstance] didReceiveRemoteNotification:userInfo fromUserNotification:NO];
}

+ (void)setDelegate:(nullable id<MSPushDelegate>)delegate {
  [[self sharedInstance] setDelegate:delegate];
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {
#if TARGET_OS_OSX
    [MS_NOTIFICATION_CENTER addObserver:self
                               selector:@selector(applicationDidFinishLaunching:)
                                   name:NSApplicationDidFinishLaunchingNotification
                                 object:nil];
#endif
    [MSAppDelegateForwarder addDelegate:self.appDelegate];
    if (!self.pushTokenHasBeenSent) {
      [self registerForRemoteNotifications];
    }
    MSLogInfo([MSPush logTag], @"Push service has been enabled.");
  } else {
#if TARGET_OS_OSX
    [MS_NOTIFICATION_CENTER removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
#endif
    [MSAppDelegateForwarder removeDelegate:self.appDelegate];
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
  [NSApp registerForRemoteNotificationTypes:(NSRemoteNotificationTypeSound | NSRemoteNotificationTypeBadge)];
#elif TARGET_OS_IOS && !TARGET_OS_SIMULATOR
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

#if TARGET_OS_OSX
- (BOOL)didReceiveUserNotification:(NSUserNotification *)notification {
  if (notification && [self didReceiveRemoteNotification:notification.userInfo fromUserNotification:YES]) {
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];

    // The delivered notification should be removed.
    [center removeDeliveredNotification:notification];
    return YES;
  }
  return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  [self didReceiveUserNotification:[notification.userInfo objectForKey:NSApplicationLaunchUserNotificationKey]];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification {
  [self didReceiveUserNotification:notification];
  if ([userNotificationCenterDelegate respondsToSelector:@selector(userNotificationCenter:didActivateNotification:)]) {
    [userNotificationCenterDelegate userNotificationCenter:center didActivateNotification:notification];
  }
}
#endif

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromUserNotification:(BOOL)userNotification {

#if !TARGET_OS_OSX
  (void)userNotification;
#endif
  MSLogVerbose([MSPush logTag], @"User info for notification was forwarded to Push: %@", [userInfo description]);
  NSString *title;
  NSString *message;
  NSDictionary *aps = [userInfo objectForKey:kMSPushNotificationApsKey];
  NSObject *alert = [aps objectForKey:kMSPushNotificationAlertKey];
  if ([alert isKindOfClass:[NSDictionary class]]) {
    title = [alert valueForKey:kMSPushNotificationTitleKey];
    message = [alert valueForKey:kMSPushNotificationMessageKey];
  } else {

    /*
     * "alert" value type can be either Dictionary or String. Try one more time if it is a String value even
     * though MobileCenterPush doesn't support String value for "alert".
     */
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

    // If Push is disabled, discard the notification.
    if (![[self class] isEnabled]) {
      MSLogVerbose(
          [MSPush logTag],
          @"Notification received while Push was enabled but Push is not disabled now, discard the notification.");
      return YES;
    }

    MSLogDebug([MSPush logTag], @"Notification received.\nTitle: %@\nMessage:%@\nCustom data: %@", title, message,
               [customData description]);

#if TARGET_OS_OSX

    /*
     * Only call the push delegate if the app is in topmost foreground and the notification is a remote notification or
     * it is a user notification. Otherwise, convert a remote notification to a user notification and handle the
     * notification when a user clicks it from notification center.
     */
    if ([NSApp isActive] || userNotification) {
#endif

      // Initialize push notification model.
      MSPushNotification *pushNotification =
          [[MSPushNotification alloc] initWithTitle:title message:message customData:customData];

      // Call push delegate and deliver notification back to the application.
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate push:self didReceivePushNotification:pushNotification];
      });
#if TARGET_OS_OSX
    } else {
      NSUserNotification *notification = [[NSUserNotification alloc] init];
      notification.title = title;
      notification.informativeText = message;
      notification.userInfo = userInfo;
      NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
      [center deliverNotification:notification];
    }
#endif
    return YES;
  }
  return NO;
}

@end
