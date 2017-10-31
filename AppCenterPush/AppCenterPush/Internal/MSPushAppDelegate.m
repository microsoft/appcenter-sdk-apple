#import "MSAppDelegateForwarder.h"
#import "MSPush.h"
#import "MSPushAppDelegate.h"

@implementation MSPushAppDelegate

#pragma mark - MSAppDelegate

#if TARGET_OS_OSX
- (void)application:(__attribute__((unused))NSApplication *)application
#else
- (void)application:(__attribute__((unused))UIApplication *)application
#endif
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  [MSPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

#if TARGET_OS_OSX
- (void)application:(__attribute__((unused))NSApplication *)application
#else
- (void)application:(__attribute__((unused))UIApplication *)application
#endif
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  [MSPush didFailToRegisterForRemoteNotificationsWithError:error];
}

#if TARGET_OS_OSX
- (void)application:(__attribute__((unused))NSApplication *)application
#else

// Workaround for iOS 10 bug. See https://forums.developer.apple.com/thread/54332
- (void)application:(__attribute__((unused))UIApplication *)application
#endif
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

@end

#pragma mark - Swizzling

@implementation MSAppDelegateForwarder (MSPush)

+ (void)load {

  // Register selectors to swizzle for Push.
  [self addAppDelegateSelectorToSwizzle:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
  [self addAppDelegateSelectorToSwizzle:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
  [self addAppDelegateSelectorToSwizzle:@selector(application:didReceiveRemoteNotification:)];
#if !TARGET_OS_OSX
  [self addAppDelegateSelectorToSwizzle:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
#endif
}

@end
