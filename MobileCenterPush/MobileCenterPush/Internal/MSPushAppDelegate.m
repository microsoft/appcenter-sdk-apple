#import "MSAppDelegateForwarder.h"
#import "MSPushAppDelegate.h"
#import "MSPush.h"

@implementation MSPushAppDelegate

#pragma mark - MSAppDelegate

- (void)application:(__attribute__((unused))UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  [MSPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(__attribute__((unused))UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  [MSPush didFailToRegisterForRemoteNotificationsWithError:error];
}

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

@end

#pragma mark - Swizzling

@implementation MSAppDelegateForwarder (MSPush)

+ (void)load {

  // Register selectors to swizzle for Push.
  [self addAppDelegateSelectorToSwizzle:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
  [self addAppDelegateSelectorToSwizzle:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)];
  [self addAppDelegateSelectorToSwizzle:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
}

@end
