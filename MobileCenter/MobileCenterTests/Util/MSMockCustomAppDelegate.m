#import <Foundation/Foundation.h>

#import "MSAppDelegateForwarder.h"
#import "MSMockCustomAppDelegate.h"

@implementation MSMockCustomAppDelegate

- (instancetype)init {
  if ((self = [super init])) {
    _delegateValidators = [NSMutableDictionary new];
  }
  return self;
}

#pragma mark - MSAppDelegate

- (BOOL)application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation
        returnedValue:(BOOL)returnedValue {
  CustomOpenURLiOS42Validator validator = self.delegateValidators[NSStringFromSelector(_cmd)];
  return validator(application, url, sourceApplication, annotation, returnedValue);
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
      returnedValue:(BOOL)returnedValue {
  CustomOpenURLiOS9Validator validator = self.delegateValidators[NSStringFromSelector(_cmd)];
  return validator(application, url, options, returnedValue);
}

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  CustomDidRegisterNotificationValidator validator = self.delegateValidators[NSStringFromSelector(_cmd)];
  validator(application, deviceToken);
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo {
  CustomDidReceiveNotificationWorkaroundValidator validator = self.delegateValidators[NSStringFromSelector(_cmd)];
  validator(application, userInfo);
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  CustomDidReceiveNotificationValidator validator = self.delegateValidators[NSStringFromSelector(_cmd)];
  validator(application, userInfo, completionHandler);
}

@end

#pragma mark - Swizzling

@implementation MSAppDelegateForwarder (MSDistribute)

+ (void)load {

  // Register selectors to swizzle for this mock.
  [self addAppDelegateSelectorToSwizzle:@selector(application:openURL:options:)];
  [self addAppDelegateSelectorToSwizzle:@selector(application:openURL:sourceApplication:annotation:)];
  [self addAppDelegateSelectorToSwizzle:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)];
  [self addAppDelegateSelectorToSwizzle:@selector(application:didReceiveRemoteNotification:)];
  [self addAppDelegateSelectorToSwizzle:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
}

@end
