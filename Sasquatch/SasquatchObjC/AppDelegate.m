#import "AppDelegate.h"
#import "MSAlertController.h"
#import "MobileCenterDelegateObjC.h"

@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;
@import MobileCenterDistribute;

@interface AppDelegate () <MSCrashesDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
  [MSMobileCenter start:@"0dbca56b-b9ae-4d53-856a-7c2856137d85" withServices:@[[MSAnalytics class], [MSCrashes class], [MSDistribute class]]];
  
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
    
    // Use MSAlertViewController to show a dialog to the user where they can choose if they want to provide a crash
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

-(void) setMobileCenterDelegate{
  SasquatchViewController *sasquatchController = (SasquatchViewController *)[(UINavigationController *)[[self window] rootViewController] topViewController];
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



@end
