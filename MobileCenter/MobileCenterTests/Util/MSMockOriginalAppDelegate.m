#import <Foundation/Foundation.h>

#import "MSAppDelegateForwarder.h"
#import "MSMockOriginalAppDelegate.h"
#import "MSAppDelegateForwarderPrivate.h"

@implementation MSMockOriginalAppDelegate

- (instancetype)init {
  if ((self = [super init])) {
    _delegateValidators = [NSMutableDictionary new];

    // Force swizzling for tests.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      [MSAppDelegateForwarder swizzleOriginalDelegate:self];
    });
  }
  return self;
}

#pragma mark - UIApplication

- (BOOL)application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation {
  OriginalOpenURLiOS42Validator validator = self.delegateValidators[NSStringFromSelector(_cmd)];
  return validator(application, url, sourceApplication, annotation);
}

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  OriginalDidRegisterNotificationValidator validator = self.delegateValidators[NSStringFromSelector(_cmd)];
  validator(application, deviceToken);
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  OriginalDidReceiveNotification validator = self.delegateValidators[NSStringFromSelector(_cmd)];
  validator(application, userInfo, completionHandler);
}

@end
