#import "AppDelegate.h"
#import "Constants.h"

@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;
@import MobileCenterDistribute;

@interface AppDelegate () <MSCrashesDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Override point for customization after application launch.

  // Start Mobile Center SDK
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];
  [MSMobileCenter setLogUrl:@"http://in-integration.dev.avalanch.es:8081"];
  [MSMobileCenter start:[[NSUUID UUID] UUIDString] withServices:@[[MSAnalytics class], [MSCrashes class], [MSDistribute class]]];
  [MSCrashes setDelegate:self];

  // Print the install Id.
  NSLog(@"%@ Install Id: %@", kDEMLogTag, [[MSMobileCenter installId] UUIDString]);
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

  /*
   * Sent when the application is about to move from active to inactive state. This can occur for certain types of
   * temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and
   * it begins the transition to the background state.
   * Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use
   * this method to pause the game.
   */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {

  /*
   * Use this method to release shared resources, save user data, invalidate timers, and store enough application state
   * information to restore your application to its current state in case it is terminated later.
   * If your application supports background execution, this method is called instead of applicationWillTerminate: when
   * the user quits.
   */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

  /*
   * Called as part of the transition from the background to the inactive state; here you can undo many of the changes
   * made on entering the background.
   */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

  /*
   * Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was
   * previously in the background, optionally refresh the user interface.
   */
}

- (void)applicationWillTerminate:(UIApplication *)application {

  /*
   * Called when the application is about to terminate. Save data if appropriate.
   * See also applicationDidEnterBackground:.
   */
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
  NSLog(@"%@ Got waken up via openURL: %@", kDEMLogTag, url);
  return YES;
}

#pragma mark - MSCrashesDelegate

- (BOOL)crashes:(MSCrashes *)crashes shouldProcessErrorReport:(MSErrorReport *)errorReport {
  return YES;
}

- (void)crashes:(MSCrashes *)crashes willSendErrorReport:(MSErrorReport *)errorReport {
}

- (void)crashes:(MSCrashes *)crashes didSucceedSendingErrorReport:(MSErrorReport *)errorReport {
}

- (void)crashes:(MSCrashes *)crashes didFailSendingErrorReport:(MSErrorReport *)errorReport withError:(NSError *)error {
}

@end
