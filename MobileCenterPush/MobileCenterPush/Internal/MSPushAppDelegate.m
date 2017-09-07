#import "MSAppDelegateForwarder.h"
#import "MSPush.h"
#import "MSPushAppDelegate.h"

@implementation MSPushAppDelegate

#pragma mark - MSAppDelegate

- (void)application:(__attribute__((unused))MSOriginalApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  [MSPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(__attribute__((unused))MSOriginalApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  [MSPush didFailToRegisterForRemoteNotificationsWithError:error];
}

// Callback for macOS + workaround for iOS 10 bug. See https://forums.developer.apple.com/thread/54332
- (void)application:(__attribute__((unused))MSOriginalApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo {
  [MSPush didReceiveRemoteNotification:userInfo];
}

#if !TARGET_OS_OSX
- (void)application:(__attribute__((unused))UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  BOOL result = [MSPush didReceiveRemoteNotification:userInfo];
  if (result) {
    completionHandler(UIBackgroundFetchResultNewData);
  } else {
    completionHandler(UIBackgroundFetchResultNoData);
  }
}
#endif

#if TARGET_OS_OSX
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
  center.delegate = self;
  [MSPush didReceiveNotification:notification];
}

/*
 * TODO This one is not an app delegate method but rather an NSUserNotificationCenter delegate method,
 * we can either have 2 classes or rename this one.
 */
- (void)userNotificationCenter:(NSUserNotificationCenter *)__unused center
       didActivateNotification:(NSUserNotification *)notification {
  [MSPush didReceiveUserNotification:notification];
}

#endif

@end

#pragma mark - Swizzling

@implementation MSAppDelegateForwarder (MSPush)

+ (void)load {

  // Register selectors to swizzle for Push.
  [self addAppDelegateSelectorToSwizzle:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
  [self addAppDelegateSelectorToSwizzle:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
  [self addAppDelegateSelectorToSwizzle:@selector(application:didReceiveRemoteNotification:)];
#if TARGET_OS_OSX
  [self addAppDelegateSelectorToSwizzle:@selector(applicationDidFinishLaunching:)];
#else
  [self addAppDelegateSelectorToSwizzle:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
#endif
}

@end
