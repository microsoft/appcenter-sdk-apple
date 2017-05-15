#import <Foundation/Foundation.h>

#import "MSAppDelegateForwarder.h"
#import "MSMockOriginalAppDelegate.h"

@implementation MSMockOriginalAppDelegate

- (instancetype)init {
  if ((self = [super init])) {
    _delegateValidators = [NSMutableDictionary new];
  }
  return self;
}

#pragma mark - UIApplication

- (BOOL)application:(UIApplication *)app
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation {
  OriginalOpenURLiOS42Validator validator = self.delegateValidators[NSStringFromSelector(_cmd)];
  return validator(app, url, sourceApplication, annotation);
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  OriginalDidRegisterNotificationValidator validator = self.delegateValidators[NSStringFromSelector(_cmd)];
  validator(app, deviceToken);
}

- (void)application:(UIApplication *)app
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  OriginalDidReceiveNotification validator = self.delegateValidators[NSStringFromSelector(_cmd)];
  validator(app, userInfo, completionHandler);
}

@end
