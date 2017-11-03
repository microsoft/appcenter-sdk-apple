#import "AppCenterDelegateObjC.h"
#import "AppDelegate.h"
#import "MSAlertController.h"

@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;
@import AppCenterDistribute;
@import AppCenterPush;

@interface AppDelegate () <MSCrashesDelegate, MSDistributeDelegate, MSPushDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Cusomize App Center SDK.
  [MSDistribute setDelegate:self];
  [MSPush setDelegate:self];
  [MSAppCenter setLogLevel:MSLogLevelVerbose];

// Start App Center SDK.
#if DEBUG
  [MSAppCenter start:@"3ccfe7f5-ec01-4de5-883c-f563bbbe147a"
           withServices:@[ [MSAnalytics class], [MSCrashes class], [MSPush class] ]];
#else
  [MSAppCenter start:@"3ccfe7f5-ec01-4de5-883c-f563bbbe147a"
           withServices:@[ [MSAnalytics class], [MSCrashes class], [MSDistribute class], [MSPush class] ]];
#endif

  [self crashes];
  [self setAppCenterDelegate];
  return YES;
}

#pragma mark - Application life cycle

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

- (void)setAppCenterDelegate {
  MSMainViewController *sasquatchController =
      (MSMainViewController *)[(UINavigationController *)[[self window] rootViewController] topViewController];
  sasquatchController.appCenter = [[AppCenterDelegateObjC alloc] init];
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

- (NSArray<MSErrorAttachmentLog *> *)attachmentsWithCrashes:(MSCrashes *)crashes
                                             forErrorReport:(MSErrorReport *)errorReport {
  MSErrorAttachmentLog *attachment1 = [MSErrorAttachmentLog attachmentWithText:@"Hello world!" filename:@"hello.txt"];
  MSErrorAttachmentLog *attachment2 =
      [MSErrorAttachmentLog attachmentWithBinary:[@"Fake image" dataUsingEncoding:NSUTF8StringEncoding]
                                        filename:@"fake_image.jpeg"
                                     contentType:@"image/jpeg"];
  return @[ attachment1, attachment2 ];
}

#pragma mark - MSDistributeDelegate

- (BOOL)distribute:(MSDistribute *)distribute releaseAvailableWithDetails:(MSReleaseDetails *)details {

  // Show a dialog to the user where they can choose if they want to update.
  MSAlertController *alertController = [MSAlertController
      alertControllerWithTitle:NSLocalizedStringFromTable(@"distribute_alert_title", @"Sasquatch", @"")
                       message:NSLocalizedStringFromTable(@"distribute_alert_message", @"Sasquatch", @"")];

  // Add a "Yes"-Button and call the notifyUpdateAction-callback with MSUpdateActionUpdate
  [alertController addCancelActionWithTitle:NSLocalizedStringFromTable(@"distribute_alert_yes", @"Sasquatch", @"")
                                    handler:^(UIAlertAction *action) {
                                      [MSDistribute notifyUpdateAction:MSUpdateActionUpdate];
                                    }];

  // Add a "No"-Button and call the notifyUpdateAction-callback with MSUpdateActionPostpone
  [alertController addDefaultActionWithTitle:NSLocalizedStringFromTable(@"distribute_alert_no", @"Sasquatch", @"")
                                     handler:^(UIAlertAction *action) {
                                       [MSDistribute notifyUpdateAction:MSUpdateActionPostpone];
                                     }];

  // Show the alert controller.
  [alertController show];
  return YES;
}

#pragma mark - MSPushDelegate

- (void)push:(MSPush *)push didReceivePushNotification:(MSPushNotification *)pushNotification {
  NSString *title = pushNotification.title;
  NSString *message = pushNotification.message;
  NSMutableString *customData = nil;
  for (NSString *key in pushNotification.customData) {
    ([customData length] == 0) ? customData = [NSMutableString new] : [customData appendString:@", "];
    [customData appendFormat:@"%@: %@", key, [pushNotification.customData objectForKey:key]];
  }
  if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
    NSLog(@"Notification received in background, title: \"%@\", message: \"%@\", custom data: \"%@\"", title, message,
          customData);
  } else {
    message = [NSString stringWithFormat:@"%@%@%@", (message ? message : @""), (message && customData ? @"\n" : @""),
                                         (customData ? customData : @"")];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
  }
}

@end
