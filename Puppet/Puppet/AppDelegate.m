#import "AppDelegate.h"
#import "Constants.h"
#import "SonomaAnalytics.h"
#import "MobileCenter.h"
#import "SonomaCrashes.h"
#import "SNMCrashesDelegate.h"

#import "SNMErrorAttachment.h"
#import "SNMErrorBinaryAttachment.h"
#import "SNMErrorReport.h"

@interface AppDelegate () <SNMCrashesDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Start Sonoma SDK.
  [MSSonoma setLogLevel:MSLogLevelVerbose];

  [MSSonoma start:@"7dfb022a-17b5-4d4a-9c75-12bc3ef5e6b7" withFeatures:@[[SNMAnalytics class], [SNMCrashes class]]];

  if ([SNMCrashes hasCrashedInLastSession]) {
    SNMErrorReport *errorReport = [SNMCrashes lastSessionCrashReport];
    NSLog(@"We crashed with Signal: %@", errorReport.signal);
    MSDevice *device = [errorReport device];
    NSString *osVersion = [device osVersion];
    NSString *appVersion = [device appVersion];
    NSString *appBuild = [device appBuild];
    NSLog(@"OS Version is: %@", osVersion);
    NSLog(@"App Version is: %@", appVersion);
    NSLog(@"App Build is: %@", appBuild);
  }

  [SNMCrashes setDelegate:self];
  [SNMCrashes setUserConfirmationHandler:(^(NSArray<SNMErrorReport *> *errorReports) {

    [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"crash_alert_title", @"Main", @"")
                                message:NSLocalizedStringFromTable(@"crash_alert_message", @"Main", @"")
                               delegate:self
                      cancelButtonTitle:NSLocalizedStringFromTable(@"crash_alert_do_not_send", @"Main", @"")
                      otherButtonTitles:NSLocalizedStringFromTable(@"crash_alert_always_send", @"Main", @""),
                                        NSLocalizedStringFromTable(@"crash_alert_send", @"Main", @""),
                                        nil]
        show];
    return YES;
  })];

  // Print the install Id.
  NSLog(@"%@ Install Id: %@", kPUPLogTag, [[MSSonoma installId] UUIDString]);
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of
  // temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and
  // it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use
  // this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state
  // information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when
  // the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes
  // made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was
  // previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also
  // applicationDidEnterBackground:.
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
  case 0:[SNMCrashes notifyWithUserConfirmation:SNMUserConfirmationDontSend];
    break;
  case 1:[SNMCrashes notifyWithUserConfirmation:SNMUserConfirmationAlways];
    break;
  case 2:[SNMCrashes notifyWithUserConfirmation:SNMUserConfirmationSend];
    break;
  }
}

#pragma mark - SNMCrashesDelegate

- (BOOL)crashes:(SNMCrashes *)crashes shouldProcessErrorReport:(SNMErrorReport *)errorReport {
  NSLog(@"Should process error report with: %@", errorReport.exceptionReason);
  return YES;
}

- (SNMErrorAttachment *)attachmentWithCrashes:(SNMCrashes *)crashes forErrorReport:(SNMErrorReport *)errorReport {
  NSLog(@"Attach additional information to error report with: %@", errorReport.exceptionReason);
  return [SNMErrorAttachment attachmentWithText:@"Text Attachment"
                                  andBinaryData:[@"Hello World" dataUsingEncoding:NSUTF8StringEncoding]
                                       filename:@"binary.txt" mimeType:@"text/plain"];
}

- (void)crashes:(SNMCrashes *)crashes willSendErrorReport:(SNMErrorReport *)errorReport {
  NSLog(@"Will send error report with: %@", errorReport.exceptionReason);
}

- (void)crashes:(SNMCrashes *)crashes didSucceedSendingErrorReport:(SNMErrorReport *)errorReport {
  NSLog(@"Did succeed error report sending with: %@", errorReport.exceptionReason);
}

- (void)crashes:(SNMCrashes *)crashes didFailSendingErrorReport:(SNMErrorReport *)errorReport withError:(NSError *)error {
  NSLog(@"Did fail sending report with: %@, and error %@",
        errorReport.exceptionReason,
        error.localizedDescription);
}

@end
