/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <UserNotifications/UserNotifications.h>
#import "AppDelegate.h"
#import "Constants.h"
#import "MobileCenter.h"
#import "MobileCenterAnalytics.h"
#import "MobileCenterCrashes.h"
#import "MobileCenterDistribute.h"
#import "MobileCenterPush.h"
#import "MSAlertController.h"

@interface AppDelegate () <MSCrashesDelegate, MSDistributeDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Customize Mobile Center SDK.
  [MSDistribute setDelegate:self];
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];

  // Start Mobile Center SDK.
  [MSMobileCenter setLogUrl:@"https://in-integration.dev.avalanch.es"];
  [MSMobileCenter start:@"2dcf4840-f4d8-49d6-bcf0-e967f01203fb" withServices:@[ [MSAnalytics class], [MSPush class] ]];

  [self crashes];

  // Print the install Id.
  NSLog(@"%@ Install Id: %@", kPUPLogTag, [[MSMobileCenter installId] UUIDString]);
  return YES;
}

#pragma mark - URL handling

/**
 *  This addition is required in case apps support iOS 8. Apps that are iOS 9 and later don't need to implement this
 * as our SDK uses SFSafariViewController for MSDistribute.
 */
- (BOOL)application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation {

  // Forward the URL to MSDistribute.
  [MSDistribute openUrl:url];
  NSLog(@"%@ Got waken up via openURL: %@", kPUPLogTag, url);
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
  NSLog(@"%@", userInfo);
  [self MessageBox:@"Notification" message:[[[userInfo objectForKey:@"aps"] valueForKey:@"alert"] description]];
}

- (void)MessageBox:(NSString *)title message:(NSString *)messageText {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                  message:messageText
                                                 delegate:self
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
  [alert show];
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
  [MSCrashes
      setUserConfirmationHandler:(^(NSArray<MSErrorReport *> *errorReports) {

        // Show a dialog to the user where they can choose if they want to provide a crash report.
        MSAlertController *alertController = [MSAlertController
            alertControllerWithTitle:NSLocalizedStringFromTable(@"crash_alert_title", @"Main", @"")
                             message:NSLocalizedStringFromTable(@"crash_alert_message", @"Main", @"")];

        // Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationDontSend
        [alertController addCancelActionWithTitle:NSLocalizedStringFromTable(@"crash_alert_do_not_send", @"Main", @"")
                                          handler:^(UIAlertAction *action) {
                                            [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
                                          }];

        // Add a "Yes"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationSend
        [alertController addDefaultActionWithTitle:NSLocalizedStringFromTable(@"crash_alert_send", @"Main", @"")
                                           handler:^(UIAlertAction *action) {
                                             [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
                                           }];

        // Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationAlways
        [alertController addDefaultActionWithTitle:NSLocalizedStringFromTable(@"crash_alert_always_send", @"Main", @"")
                                           handler:^(UIAlertAction *action) {
                                             [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];
                                           }];
        // Show the alert controller.
        [alertController show];

        return YES;
      })];
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
  if ([[[NSUserDefaults new] objectForKey:kPUPCustomizedUpdateAlertKey] isEqual:@1]) {

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
  return NO;
}

@end
