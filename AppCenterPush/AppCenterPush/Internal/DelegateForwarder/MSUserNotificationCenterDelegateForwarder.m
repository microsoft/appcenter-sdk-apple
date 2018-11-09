#import <Foundation/Foundation.h>
#if !TARGET_OS_OSX
#import <UserNotifications/UserNotifications.h>
#endif

#import "MSPush.h"
#import "MSUserNotificationCenterDelegateForwarder.h"

static dispatch_once_t swizzlingOnceToken;

// Singleton instance.
static MSUserNotificationCenterDelegateForwarder *sharedInstance = nil;

@implementation MSUserNotificationCenterDelegateForwarder

+ (void)load {
  [[self sharedInstance] setEnabledFromPlistForKey:kMSUserNotificationCenterDelegateForwarderEnabledKey];

  // TODO test the forwarder on macOS.
  // Register selectors to swizzle (iOS 10+).
#if !TARGET_OS_OSX
  if ([[MSUserNotificationCenterDelegateForwarder sharedInstance] originalClassForSetDelegate]) {
    [[MSUserNotificationCenterDelegateForwarder sharedInstance]
        addDelegateSelectorToSwizzle:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)];
    [[MSUserNotificationCenterDelegateForwarder sharedInstance]
        addDelegateSelectorToSwizzle:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)];
  }
#endif
}

+ (void)doNothingButForceLoadTheClass{
  // This method doesn't need to do anything it's purpose is just to force load this class into the runtime.
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

#if !TARGET_OS_OSX

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

  /*
   * First, forward to the original delegate, customers can leverage the completion handler later in their Push callback.
   * It's now a responsibility of the original delegate to call the completion handler.
   */
  [[MSUserNotificationCenterDelegateForwarder sharedInstance].originalImplementations[NSStringFromSelector(_cmd)] getValue:&originalImp];
  if (originalImp) {
    ((void (*)(id, SEL, UNUserNotificationCenter *, UNNotification *, void (^)(UNNotificationPresentationOptions options)))originalImp)(
        self, _cmd, center, notification, completionHandler);
  }

  // Then, forward to Push.
  [MSPush didReceiveRemoteNotification:notification.request.content.userInfo];
  if (!originalImp) {

    // No original implementation, we have to call the completion handler ourselves with the default behavior.
    completionHandler(UNNotificationPresentationOptionNone);
  }
}

- (void)custom_userNotificationCenter:(UNUserNotificationCenter *)center
       didReceiveNotificationResponse:(UNNotificationResponse *)response
                withCompletionHandler:(void (^)(void))completionHandler {
  IMP originalImp = NULL;

  /*
   * First, forward to the original delegate, customers can leverage the completion handler later in their Push callback.
   * It's now a responsability of the original delegate to call the completion handler.
   */
  [[MSUserNotificationCenterDelegateForwarder sharedInstance].originalImplementations[NSStringFromSelector(_cmd)] getValue:&originalImp];
  if (originalImp) {
    ((void (*)(id, SEL, UNUserNotificationCenter *, UNNotificationResponse *, void (^)(void)))originalImp)(self, _cmd, center, response,
                                                                                                           completionHandler);
  }

  // Then, forward to Push.
  [MSPush didReceiveRemoteNotification:response.notification.request.content.userInfo];
  if (!originalImp) {

    // No original implementation, we have to call the completion handler ourselves.
    completionHandler();
  }
}

#pragma clang diagnostic pop

#endif

@end
