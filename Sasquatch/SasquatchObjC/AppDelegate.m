#import "AppDelegate.h"
#import "MSAlertController.h"
#import "MobileCenterDelegateObjC.h"

@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;
@import MobileCenterDistribute;
@import MobileCenterPush;

@interface AppDelegate () <MSCrashesDelegate, MSDistributeDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Cusomize Mobile Center SDK.
  [MSDistribute setDelegate:self];
  [MSPush setDelegate:self];
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];

// Start Mobile Center SDK.
#if DEBUG
  [MSMobileCenter start:@"3ccfe7f5-ec01-4de5-883c-f563bbbe147a"
           withServices:@[ [MSAnalytics class], [MSCrashes class], [MSPush class] ]];
#else
  [MSMobileCenter start:@"3ccfe7f5-ec01-4de5-883c-f563bbbe147a"
           withServices:@[ [MSAnalytics class], [MSCrashes class], [MSDistribute class], [MSPush class] ]];
#endif

  [self crashes];
  [self setMobileCenterDelegate];
  return YES;
}

#pragma mark - Application life cycle

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  [MSPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error {
  [MSPush didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  BOOL result = [MSPush didReceiveRemoteNotification:userInfo];
  if (result) {
    completionHandler(UIBackgroundFetchResultNewData);
  } else {
    completionHandler(UIBackgroundFetchResultNoData);
  }
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

#pragma mark - Private

- (void)crashes {
  if ([MSCrashes hasCrashedInLastSession]) {
    MSErrorReport *errorReport = [MSCrashes lastSessionCrashReport];
    NSLog(@"We crashed with Signal: %@", errorReport.signal);
    MSDevice *device = [errorReport device];
    NSString *osVersion = [device osVersion];
    NSString *appVersion = [device appVersion];
    NSString *appBuild = [device appBuild];
    NSLog(@"OS Version is: %@", osVersion);
    NSLog(@"App Version is: %@", appVersion);
    NSLog(@"App Build is: %@", appBuild);
  }

  [MSCrashes setDelegate:self];
  [MSCrashes setUserConfirmationHandler:(^(NSArray<MSErrorReport *> *errorReports) {

               // Use MSAlertViewController to show a dialog to the user where they can choose if they want to provide a
               // crash
               // report.
               MSAlertController *alertController = [MSAlertController
                   alertControllerWithTitle:@"Sorry about that!"
                                    message:@"Do you want to send an anonymous crash report so we can fix the issue?"];

               // Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationDontSend
               [alertController addCancelActionWithTitle:@"Don't Send"
                                                 handler:^(UIAlertAction *action) {
                                                   [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
                                                 }];

               // Add a "Yes"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationSend
               [alertController addDefaultActionWithTitle:@"Send"
                                                  handler:^(UIAlertAction *action) {
                                                    [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
                                                  }];

               // Add a "Always"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationAlways
               [alertController addDefaultActionWithTitle:@"Always Send"
                                                  handler:^(UIAlertAction *action) {
                                                    [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];
                                                  }];
               // Show the alert controller.
               [alertController show];

               return YES;
             })];
}

- (void)setMobileCenterDelegate {
  MSMainViewController *sasquatchController =
      (MSMainViewController *)[(UINavigationController *)[[self window] rootViewController] topViewController];
  sasquatchController.mobileCenter = [[MobileCenterDelegateObjC alloc] init];
}

#pragma mark - MSCrashesDelegate

- (BOOL)crashes:(MSCrashes *)crashes shouldProcessErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"Should process error report with: %@", errorReport.exceptionReason);
  return YES;
}

- (void)crashes:(MSCrashes *)crashes willSendErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"Will send error report with: %@", errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes didSucceedSendingErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"Did succeed error report sending with: %@", errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes didFailSendingErrorReport:(MSErrorReport *)errorReport withError:(NSError *)error {
  NSLog(@"Did fail sending report with: %@, and error: %@", errorReport.exceptionReason, error.localizedDescription);
}

#pragma mark - MSDistributeDelegate

- (BOOL)distribute:(MSDistribute *)distribute releaseAvailableWithDetails:(MSReleaseDetails *)details {

  // Show a dialog to the user where they can choose if they want to update.
  MSAlertController *alertController = [MSAlertController
      alertControllerWithTitle:NSLocalizedStringFromTable(@"distribute_alert_title", @"Main", @"")
                       message:NSLocalizedStringFromTable(@"distribute_alert_message", @"Main", @"")];

  // Add a "Yes"-Button and call the notifyUpdateAction-callback with MSUpdateActionUpdate
  [alertController addCancelActionWithTitle:NSLocalizedStringFromTable(@"distribute_alert_yes", @"Main", @"")
                                    handler:^(UIAlertAction *action) {
                                      [MSDistribute notifyUpdateAction:MSUpdateActionUpdate];
                                    }];

  // Add a "No"-Button and call the notifyUpdateAction-callback with MSUpdateActionPostpone
  [alertController addDefaultActionWithTitle:NSLocalizedStringFromTable(@"distribute_alert_no", @"Main", @"")
                                     handler:^(UIAlertAction *action) {
                                       [MSDistribute notifyUpdateAction:MSUpdateActionPostpone];
                                     }];

  // Show the alert controller.
  [alertController show];
  return YES;
}

#pragma mark - MSPushDelegate

- (void)push:(MSPush *)push didReceivePushNotification:(MSPushNotification *)pushNotification {
  NSString *message = pushNotification.message;
  for (NSString *key in pushNotification.customData) {
    message = [NSString stringWithFormat:@"%@\n%@: %@", message, key, [pushNotification.customData objectForKey:key]];
  }
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:pushNotification.title
                                                  message:message
                                                 delegate:self
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
  [alert show];
}

@end
