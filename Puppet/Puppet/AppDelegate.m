#import "AppDelegate.h"
#import "AvalancheAnalytics.h"
#import "AvalancheCrashes.h"
#import "AvalancheHub.h"
#import "Constants.h"

#import "AVAErrorAttachment.h"
#import "AVAErrorReport.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Start Avalanche SDK.
  [AVAAvalanche setLogLevel:AVALogLevelVerbose];
  [AVAAvalanche start:@[ [AVAAnalytics class], [AVAErrorReporting class] ] withAppSecret:[[NSUUID UUID] UUIDString]];

  [AVAErrorReporting setErrorLoggingDelegate:self]; // TODO rename to setDelegate:

  [AVAErrorReporting setUserConfirmationHandler:^(NSArray<AVAErrorReport *> *errorLogs) {
    NSString *exceptionReason = [AVAErrorReporting lastSessionCrashDetails].exceptionReason;

    // or something like

    NSString *foo = [errorLogs firstObject].exceptionReason;
    if (foo) {
      // Do something with exceptionReason
      NSLog(@"%@", foo);
    }

    UIAlertView *customAlertView = [[UIAlertView alloc] initWithTitle:@"Oh no! The App crashed"
                                                              message:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Don't send"
                                                    otherButtonTitles:@"Send", nil];
    if (exceptionReason) {
      customAlertView.message =
          @"We would like to send a crash report to the developers. Please enter a short description of what happened:";
      customAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    } else {
      customAlertView.message = @"We would like to send a crash report to the developers";
    }

    [customAlertView show];
  }];

  // Print the install Id.
  NSLog(@"%@ Install Id: %@", kPUPLogTag, [[AVAAvalanche installId] UUIDString]);
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

// TODO talk to andreas and lukas about this again

- (BOOL)errorReporting:(AVAErrorReporting *)crashes shouldProcess:(AVAErrorReport *)errorReport {

  if ([errorReport.exceptionReason isEqualToString:@"something"]) {
    return false;
  } else {
    return true;
  }
}

- (AVAErrorAttachment *)attachmentWithErrorReporting:(AVAErrorReporting *)crashes forErrorReport:(AVAErrorReport *)errorLog {

  return [AVAErrorAttachment new];
}

- (void)errorReportingWillSend:(AVAErrorReporting *)crashes {
}

- (void)errorReporting:(AVAErrorReporting *)crashes didFailSending:(AVAErrorReport *)errorLog withError:(NSError *)error {
}

- (void)errorReporting:(AVAErrorReporting *)crashes didSucceedSending:(AVAErrorReport *)errorLog {
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (alertView.alertViewStyle != UIAlertViewStyleDefault) {
  }
  switch (buttonIndex) {
  case 0:
    [AVAErrorReporting notifyWithUserConfirmation:AVAUserConfirmationDontSend];
    break;
  case 1:
    [AVAErrorReporting notifyWithUserConfirmation:AVAUserConfirmationAlways];
    break;
  default:
    [AVAErrorReporting notifyWithUserConfirmation:AVAUserConfirmationDontSend];
    break;
  }
}

@end
