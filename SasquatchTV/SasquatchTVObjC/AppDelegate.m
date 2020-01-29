// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppDelegate.h"
#import "AppCenterDelegateObjC.h"

@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;

@interface AppDelegate () <MSCrashesDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [MSAppCenter setLogLevel:MSLogLevelVerbose];
  [MSAppCenter start:@"84cb4635-1666-46f6-abc7-1a1ce9be8fef" withServices:@ [[MSAnalytics class], [MSCrashes class]]];
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

               // Use MSAlertViewController to show a dialog to the user where they can choose if they want to provide a crash report.
               UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Sorry about that!"
                                                                                        message:@"Do you want to send an anonymous crash "
                                                                                                @"report so we can fix the issue?"
                                                                                 preferredStyle:UIAlertControllerStyleAlert];

               // Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationDontSend.
               [alertController addAction:[UIAlertAction actionWithTitle:@"Don't Send"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction *action) {
                                                                   [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
                                                                 }]];

               // Add a "Yes"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationSend.
               [alertController addAction:[UIAlertAction actionWithTitle:@"Send"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                   [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
                                                                 }]];

               // Add a "Always"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationAlways.
               [alertController addAction:[UIAlertAction actionWithTitle:@"Always Send"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                   [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];
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

- (NSArray<MSErrorAttachmentLog *> *)attachmentsWithCrashes:(MSCrashes *)crashes forErrorReport:(MSErrorReport *)errorReport {
  MSErrorAttachmentLog *attachment1 = [MSErrorAttachmentLog attachmentWithText:@"Hello world!" filename:@"hello.txt"];
  MSErrorAttachmentLog *attachment2 = [MSErrorAttachmentLog attachmentWithBinary:[@"Fake image" dataUsingEncoding:NSUTF8StringEncoding]
                                                                        filename:@"fake_image.jpeg"
                                                                     contentType:@"image/jpeg"];
  return @[ attachment1, attachment2 ];
}

@end
