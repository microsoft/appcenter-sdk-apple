#import "AppDelegate.h"
#import "AvalancheAnalytics.h"
#import "AvalancheCrashes.h"
#import "AvalancheHub.h"
#import "Constants.h"

#import "AVAErrorAttachment.h"
#import "AVAPublicErrorLog.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Start Avalanche SDK.
  [AVAAvalanche setLogLevel:AVALogLevelVerbose];
  [AVAAvalanche useFeatures:@[[AVAAnalytics class], [AVACrashes class] ] withAppKey:[[NSUUID UUID] UUIDString]];
  
  [AVACrashes setErrorLoggingDelegate:self];
  
  [AVACrashes setAlertViewHandler: ^() {
      NSString *exceptionReason = [AVACrashes lastSessionCrashDetails].crashReason;
      UIAlertView *customAlertView = [[UIAlertView alloc] initWithTitle: @"Oh no! The App crashed"
                                                                message: nil
                                                               delegate: self
                                                      cancelButtonTitle: @"Don't send"
                                                      otherButtonTitles: @"Send", @"Always send", nil];
      if (exceptionReason) {
        customAlertView.message = @"We would like to send a crash report to the developers. Please enter a short description of what happened:";
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

- (AVAErrorAttachment *) attachmentForErrorReporting: (AVACrashes *)crashes forErrorReport:(AVAPublicErrorLog *)errorLog {
  
  return [AVAErrorAttachment new];
}

- (void)errorReportingWillSend:(AVACrashes *)crashes {
  
}

- (BOOL)errorReporting:(AVACrashes *)crashes considerErrorReport:(AVAPublicErrorLog *)errorLog {
  
  if([errorLog.crashReason isEqualToString:@"something"]) {
    return false;
  }
  else {
    return true;

  }
}

- (void)errorReporting:(AVACrashes *)crashes didFailSendingErrorLog:(AVAPublicErrorLog *)errorLog {
  
}

- (void)errorReporting:(AVACrashes *)crashes didSucceedSendingErrorLog:(AVAPublicErrorLog *)errorLog {
  
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (alertView.alertViewStyle != UIAlertViewStyleDefault) {
//    crashMetaData.userDescription = [alertView textFieldAtIndex:0].text;
  }
  switch (buttonIndex) {
    case 0:
      [AVACrashes handleUserInput:AVAErrorLoggingUserInputDontSend];
      break;
    case 1:
      [AVACrashes handleUserInput:AVAErrorLoggingUserInputSend];
      break;
    case 2:
      [AVACrashes handleUserInput:AVAErrorLoggingUserInputAlwaysSend];
      break;
  }
}

@end
