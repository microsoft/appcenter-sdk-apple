// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppDelegate.h"
#import "AppCenterDelegateObjC.h"

@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;

@interface AppDelegate () <MSACCrashesDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [MSACAppCenter setLogLevel:MSACLogLevelVerbose];
  [MSACAppCenter start:@"84cb4635-1666-46f6-abc7-1a1ce9be8fef" withServices:@[ [MSACAnalytics class], [MSACCrashes class]]];
  [self crashes];
  [self setAppCenterCenterDelegate];
  return YES;
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
  if ([MSACCrashes hasCrashedInLastSession]) {
    MSACErrorReport *errorReport = [MSACCrashes lastSessionCrashReport];
    NSLog(@"We crashed with Signal: %@", errorReport.signal);
    MSACDevice *device = [errorReport device];
    NSString *osVersion = [device osVersion];
    NSString *appVersion = [device appVersion];
    NSString *appBuild = [device appBuild];
    NSLog(@"OS Version is: %@", osVersion);
    NSLog(@"App Version is: %@", appVersion);
    NSLog(@"App Build is: %@", appBuild);
  }

  [MSACCrashes setDelegate:self];
  [MSACCrashes setUserConfirmationHandler:(^(NSArray<MSACErrorReport *> *errorReports) {
                 // Use MSAlertViewController to show a dialog to the user where they can choose if they want to provide a crash report.
                 UIAlertController *alertController =
                     [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sorry about that!", nil)
                                                         message:NSLocalizedString(@"Do you want to send an anonymous crash "
                                                                                   @"report so we can fix the issue?",
                                                                                   nil)
                                                  preferredStyle:UIAlertControllerStyleAlert];

                 // Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSACUserConfirmationDontSend.
                 [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Don't Send", nil)
                                                                     style:UIAlertActionStyleCancel
                                                                   handler:^(UIAlertAction *action) {
                                                                     [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationDontSend];
                                                                   }]];

                 // Add a "Yes"-Button and call the notifyWithUserConfirmation-callback with MSACUserConfirmationSend.
                 [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Send", nil)
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction *action) {
                                                                     [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationSend];
                                                                   }]];

                 // Add a "Always"-Button and call the notifyWithUserConfirmation-callback with MSACUserConfirmationAlways.
                 [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Always Send", nil)
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction *action) {
                                                                     [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationAlways];
                                                                   }]];
                 // Show the alert controller.
                 [[[self window] rootViewController] presentViewController:alertController animated:YES completion:nil];
                 return YES;
               })];
}

- (void)setAppCenterCenterDelegate {
  AppCenterViewController *sasquatchController = (AppCenterViewController *)[[self window] rootViewController];
  sasquatchController.appCenter = [[AppCenterDelegateObjC alloc] init];
}

#pragma mark - MSACCrashesDelegate

- (BOOL)crashes:(nonnull MSACCrashes *)crashes shouldProcessErrorReport:(nonnull MSACErrorReport *)errorReport {
  NSLog(@"Should process error report with: %@", errorReport.exceptionReason);
  return YES;
}

- (void)crashes:(nonnull MSACCrashes *)crashes willSendErrorReport:(nonnull MSACErrorReport *)errorReport {
  NSLog(@"Will send error report with: %@", errorReport.exceptionReason);
}

- (void)crashes:(nonnull MSACCrashes *)crashes didSucceedSendingErrorReport:(nonnull MSACErrorReport *)errorReport {
  NSLog(@"Did succeed error report sending with: %@", errorReport.exceptionReason);
}

- (void)crashes:(nonnull MSACCrashes *)crashes
    didFailSendingErrorReport:(nonnull MSACErrorReport *)errorReport
                    withError:(nullable NSError *)error {
  NSLog(@"Did fail sending report with: %@, and error: %@", errorReport.exceptionReason, error.localizedDescription);
}

- (NSArray<MSACErrorAttachmentLog *> *)attachmentsWithCrashes:(MSACCrashes *)crashes forErrorReport:(MSACErrorReport *)errorReport {
  MSACErrorAttachmentLog *attachment1 = [MSACErrorAttachmentLog attachmentWithText:@"Hello world!" filename:@"hello.txt"];
  MSACErrorAttachmentLog *attachment2 = [MSACErrorAttachmentLog attachmentWithBinary:[@"Fake image" dataUsingEncoding:NSUTF8StringEncoding]
                                                                            filename:@"fake_image.jpeg"
                                                                         contentType:@"image/jpeg"];
  return @[ attachment1, attachment2 ];
}

@end
