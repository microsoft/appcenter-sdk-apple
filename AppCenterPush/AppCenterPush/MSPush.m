#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#else
#import <UserNotifications/UserNotifications.h>
#endif

#import "MSAppCenterInternal.h"
#import "MSAppDelegateForwarder.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSPush.h"
#import "MSPushAppDelegate.h"
#import "MSPushLog.h"
#import "MSPushNotificationInternal.h"
#import "MSPushPrivate.h"
#import "MSUserIdContext.h"
#import "MSUserNotificationCenterDelegateForwarder.h"

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

#if TARGET_OS_OSX
/**
 * Key for NSUserNotificationCenter delegate property.
 */
static NSString *const kMSUserNotificationCenterDelegateKey = @"delegate";
#endif

/**
 * Singleton.
 */
static MSPush *sharedInstance = nil;
static dispatch_once_t onceToken;
#if TARGET_OS_OSX
static void *UserNotificationCenterDelegateContext = &UserNotificationCenterDelegateContext;
#endif

@implementation MSPush

@synthesize channelUnitConfiguration = _channelUnitConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {

    // Init channel configuration.
    _channelUnitConfiguration = [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];
    _appDelegate = [MSPushAppDelegate new];

    // This call is used to force load the MSUserNotificationCenterDelegateForwarder class to register the swizzling.
    [MSUserNotificationCenterDelegateForwarder doNothingButForceLoadTheClass];
#if TARGET_OS_OSX
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];

    /*
     * If there is a user notification center delegate already set by a customer before starting Push, assign the delegate to custom user
     * notification center delegate.
     */
    if (center.delegate) {
      _originalUserNotificationCenterDelegate = center.delegate;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (context == UserNotificationCenterDelegateContext && [keyPath isEqualToString:kMSUserNotificationCenterDelegateKey]) {
    id delegate = [change objectForKey:NSKeyValueChangeNewKey];
    if (delegate != self) {
      self.originalUserNotificationCenterDelegate = delegate;
      [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    }
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

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
  MSLogVerbose([MSPush logTag], @"Started push service.");
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

+ (NSString *)logTag {
  return @"AppCenterPush";
}

- (NSString *)groupId {
  return kMSGroupId;
}

#pragma mark - MSPush

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  [[MSPush sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  [[MSPush sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
}

+ (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo {
  return [[MSPush sharedInstance] didReceiveRemoteNotification:userInfo fromUserNotification:NO];
}

+ (void)setDelegate:(nullable id<MSPushDelegate>)delegate {
  [[MSPush sharedInstance] setDelegate:delegate];
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
    [[MSAppDelegateForwarder sharedInstance] addDelegate:self.appDelegate];
    if (!self.pushToken) {
      [self registerForRemoteNotifications];
    }
    MSLogInfo([MSPush logTag], @"Push service has been enabled.");
  } else {
#if TARGET_OS_OSX
    [MS_NOTIFICATION_CENTER removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
#endif
    [[MSAppDelegateForwarder sharedInstance] removeDelegate:self.appDelegate];
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
#elif TARGET_OS_IOS
  if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
    UIUserNotificationType allNotificationTypes =
        (UIUserNotificationType)(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
  } else {

// Ignore the partial availability warning as the compiler doesn't get that we checked for pre-iOS 10 already.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions authOptions =
        (UNAuthorizationOptions)(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge);
    [center requestAuthorizationWithOptions:authOptions
                          completionHandler:^(BOOL granted, NSError *_Nullable error) {
                            if (granted) {
                              MSLogVerbose([MSPush logTag], @"Push notifications authorization was granted.");
                            } else {
                              MSLogVerbose([MSPush logTag], @"Push notifications authorization was denied.");
                            }
                            if (error) {
                              MSLogWarning([MSPush logTag], @"Push notifications authorization request has been finished with error: %@",
                                           error.localizedDescription);
                            }
                          }];
#pragma clang diagnostic pop
  }
  [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
}

- (NSString *)convertTokenToString:(NSData *)token {
  if (!token) {
    return nil;
  }
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
  log.userId = [[MSUserIdContext sharedInstance] userId];
  [self.channelUnit enqueueItem:log flags:MSFlagsDefault];
}

#pragma mark - Register callbacks

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  MSLogVerbose([MSPush logTag], @"Registering for push notifications has been finished successfully");
  NSString *pushToken = [self convertTokenToString:deviceToken];
  if ([pushToken isEqualToString:self.pushToken]) {
    return;
  }
  self.pushToken = pushToken;
  [MS_USER_DEFAULTS setObject:pushToken forKey:kMSPushServiceStorageKey];
  [self sendPushToken:pushToken];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  MSLogWarning([MSPush logTag], @"Registering for push notifications has been finished with error: %@", error.localizedDescription);
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

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
  [self didReceiveUserNotification:notification];
  if ([self.originalUserNotificationCenterDelegate respondsToSelector:@selector(userNotificationCenter:didActivateNotification:)]) {
    [self.originalUserNotificationCenterDelegate userNotificationCenter:center didActivateNotification:notification];
  }
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {

  // Testing if the selector is defined in NSUserNotificationCenterDelegate or not.
  struct objc_method_description hasMethod =
      protocol_getMethodDescription(@protocol(NSUserNotificationCenterDelegate), [anInvocation selector], NO, YES);
  if (hasMethod.name != NULL && [self.originalUserNotificationCenterDelegate respondsToSelector:[anInvocation selector]]) {
    [anInvocation invokeWithTarget:self.originalUserNotificationCenterDelegate];
  } else {
    [super forwardInvocation:anInvocation];
  }
}
#endif

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromUserNotification:(BOOL)userNotification {

#if !TARGET_OS_OSX
  (void)userNotification;
#endif
  MSLogVerbose([MSPush logTag], @"User info for notification was forwarded to Push: %@", [userInfo description]);
  NSObject *title, *message, *customData, *alert;
  NSDictionary *aps = userInfo[kMSPushNotificationApsKey];

  // The notification is not for App Center if customData is nil. Ignore the notification.
  customData = userInfo[kMSPushNotificationCustomDataKey] ?: userInfo[kMSPushNotificationOldCustomDataKey];
  customData = ([customData isKindOfClass:[NSDictionary<NSString *, NSString *> class]]) ? customData : nil;
  if (customData) {

    // If Push is disabled, discard the notification.
    if (![[self class] isEnabled]) {
      MSLogVerbose([MSPush logTag], @"Notification received while Push was ]enabled but it is disabled now, discard the notification.");
      return YES;
    }
    alert = aps[kMSPushNotificationAlertKey];

    // Retrieve notification payload.
    if ([alert isKindOfClass:[NSDictionary class]]) {
      title = [alert valueForKey:kMSPushNotificationTitleKey];
      message = [alert valueForKey:kMSPushNotificationMessageKey];
    } else {

      /*
       * "alert" value type can be either Dictionary or String. Try one more time if it is a String value even though AppCenterPush doesn't
       * support String value for "alert".
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

    // Clean values, sometimes we get NSNull from the info dictionary as object type on optional fields.
    title = ([title isKindOfClass:[NSString class]]) ? title : nil;
    message = ([message isKindOfClass:[NSString class]]) ? message : nil;
    MSLogDebug([MSPush logTag], @"Notification received.\nTitle: %@\nMessage:%@\nCustom data: %@", title, message,
               [customData description]);

#if TARGET_OS_OSX

    /*
     * Only call the push delegate if the app is in topmost foreground and the notification is a remote notification or it is a user
     * notification.
     * Otherwise, convert a remote notification to a user notification and handle the notification when a user clicks it from notification
     * center.
     */
    if ([NSApp isActive] || userNotification) {
#endif

      // Initialize push notification model.
      MSPushNotification *pushNotification = [[MSPushNotification alloc] initWithTitle:(NSString *)title
                                                                               message:(NSString *)message
                                                                            customData:(NSDictionary<NSString *, NSString *> *)customData];

      // Call push delegate and deliver notification back to the application.
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate push:self didReceivePushNotification:pushNotification];
      });
#if TARGET_OS_OSX
    } else {
      NSUserNotification *notification = [[NSUserNotification alloc] init];
      notification.title = (NSString *)title;
      notification.informativeText = (NSString *)message;
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
