#import "MSUserNotificationCenterDelegateForwarder.h"
#import "MSPush.h"
#import <UserNotifications/UserNotifications.h>

// Singleton instance.
static MSUserNotificationCenterDelegateForwarder *sharedInstance = nil;
static dispatch_once_t swizzlingOnceToken;

@implementation MSUserNotificationCenterDelegateForwarder

+ (void)load {

  // Register selectors to swizzle (iOS 10+).
  if ([[MSUserNotificationCenterDelegateForwarder sharedInstance] originalClassForSetDelegate]) {
    [[MSUserNotificationCenterDelegateForwarder sharedInstance]
        addAppDelegateSelectorToSwizzle:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)];
    [[MSUserNotificationCenterDelegateForwarder sharedInstance]
        addAppDelegateSelectorToSwizzle:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)];
  }
}

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [self new];
  });
  return sharedInstance;
}

+ (void)resetSharedInstance {
  sharedInstance = [self new];
}

- (Class)originalClassForSetDelegate {

  // TODO Use @available API when deprecating Xcode 8.
  return NSClassFromString(@"UNUserNotificationCenter");
}

- (dispatch_once_t *)swizzlingOnceToken {
  return &swizzlingOnceToken;
}

#pragma mark - Custom Application

#pragma clang diagnostic push

// TODO Use @available API and availability attribute when deprecating Xcode 8 then we can try removing these pragma.
#pragma clang diagnostic ignored "-Wpartial-availability"

- (void)custom_setDelegate:(id<UNUserNotificationCenterDelegate>)delegate {

  // Swizzle only once.
  static dispatch_once_t delegateSwizzleOnceToken;
  dispatch_once(&delegateSwizzleOnceToken, ^{
    // Swizzle the delegate object before it's actually set.
    [[MSUserNotificationCenterDelegateForwarder sharedInstance] swizzleOriginalDelegate:delegate];
  });

  // Forward to the original `setDelegate:` implementation.
  IMP originalImp = [MSUserNotificationCenterDelegateForwarder sharedInstance].originalSetDelegateImp;
  if (originalImp) {
    ((void (*)(id, SEL, id<UNUserNotificationCenterDelegate>))originalImp)(self, _cmd, delegate);
  }
}

#pragma mark - Custom UNUserNotificationCenterDelegate

- (void)custom_userNotificationCenter:(UNUserNotificationCenter *)center
              willPresentNotification:(UNNotification *)notification
                withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
  IMP originalImp = NULL;

  // Forward to the original delegate.
  [[MSUserNotificationCenterDelegateForwarder sharedInstance].originalImplementations[NSStringFromSelector(_cmd)] getValue:&originalImp];
  if (originalImp) {
    ((void (*)(id, SEL, UNUserNotificationCenter *, UNNotification *, void (^)(UNNotificationPresentationOptions options)))originalImp)(
        self, _cmd, center, notification, completionHandler);
  }

  // Forward to Push.
  [MSPush didReceiveRemoteNotification:notification.request.content.userInfo];

  // TODO handle completion
  completionHandler(0);
}

- (void)custom_userNotificationCenter:(UNUserNotificationCenter *)center
       didReceiveNotificationResponse:(UNNotificationResponse *)response
                withCompletionHandler:(void (^)(void))completionHandler {
  IMP originalImp = NULL;

  // Forward to the original delegate.
  [[MSUserNotificationCenterDelegateForwarder sharedInstance].originalImplementations[NSStringFromSelector(_cmd)] getValue:&originalImp];
  if (originalImp) {
    ((void (*)(id, SEL, UNUserNotificationCenter *, UNNotificationResponse *, void (^)(void)))originalImp)(self, _cmd, center, response,
                                                                                                           completionHandler);
  }

  [MSPush didReceiveRemoteNotification:response.notification.request.content.userInfo];

  // TODO handle completion
  completionHandler();
}

#pragma clang diagnostic pop

@end
