#import "AppDelegate.h"
#import "MSAlertController.h"
#import "MobileCenterDelegateObjC.h"

@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;

@implementation AppDelegate

- (instancetype)init{
  self = [super init];
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];
  [MSMobileCenter setLogUrl:@"https://in-integration.dev.avalanch.es"];
  [MSMobileCenter start:@"8649b73e-6df0-4985-a039-8ab1453d44f3"
           withServices:@[ [MSAnalytics class], [MSCrashes class] ]];
  [self setupCrashes];
  [MobileCenterProvider shared].mobileCenter = [[MobileCenterDelegateObjC alloc] init];
  return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

}

#pragma mark - Private

- (void)setupCrashes {
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
                                    message:@"Do you want to send an anonymous crash report so we can fix the issue?"
                                      style:NSAlertStyleWarning];

               // Add a "Always"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationAlways
               [alertController addActionWithTitle:@"Always Send"
                                           handler:^() {
                                             [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];
                                           }];

               // Add a "Yes"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationSend
               [alertController addActionWithTitle:@"Send"
                                           handler:^() {
                                             [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
                                           }];

               // Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationDontSend
               [alertController addActionWithTitle:@"Don't Send"
                                           handler:^() {
                                             [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
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

@end
