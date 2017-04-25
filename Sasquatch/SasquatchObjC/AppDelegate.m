#import "AppDelegate.h"
#import "MSAlertController.h"
#import "MobileCenterDelegateObjC.h"

@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;
@import MobileCenterDistribute;

@interface AppDelegate () <MSCrashesDelegate, MSDistributeDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Cusomize Mobile Center SDK.
  [MSDistribute setDelegate:self];
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];

// Start Mobile Center SDK.
#if DEBUG
  [MSMobileCenter start:@"3ccfe7f5-ec01-4de5-883c-f563bbbe147a"
           withServices:@[ [MSAnalytics class], [MSCrashes class] ]];
#else
  [MSMobileCenter start:@"3ccfe7f5-ec01-4de5-883c-f563bbbe147a"
           withServices:@[ [MSAnalytics class], [MSCrashes class], [MSDistribute class] ]];
#endif

  [self crashes];
  [self setMobileCenterDelegate];
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

- (BOOL)distribute:(MSDistribute *)distribute onReleaseAvailableWithDetails:(MSReleaseDetails *)details {
  return NO;
}

@end
