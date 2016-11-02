#import "AppDelegate.h"
#import "Constants.h"

@import SonomaCore;
@import SonomaCrashes;
@import SonomaAnalytics;

@interface AppDelegate () <SNMCrashesDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.

  // Start Sonoma SDK
  [MSSonoma setLogLevel:SNMLogLevelVerbose];
  [MSSonoma setServerUrl:@"http://in-integration.dev.avalanch.es:8081"];
  [MSSonoma start:[[NSUUID UUID] UUIDString] withFeatures:@[[SNMAnalytics class], [SNMCrashes class]]];
  [SNMCrashes setDelegate:self];

  // Print the install Id.
  NSLog(@"%@ Install Id: %@", kDEMLogTag, [[MSSonoma installId] UUIDString]);
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

#pragma mark - SNMCrashesDelegate

- (BOOL)crashes:(SNMCrashes *)crashes shouldProcessErrorReport:(SNMErrorReport *)errorReport {
  return YES;
}

- (SNMErrorAttachment *)attachmentWithCrashes:(SNMCrashes *)crashes forErrorReport:(SNMErrorReport *)errorReport {
  return [SNMErrorAttachment attachmentWithText:@"Text Attachment"
                                  andBinaryData:[@"Hello World" dataUsingEncoding:NSUTF8StringEncoding]
                                       filename:@"binary.txt" mimeType:@"text/plain"];
}

- (void)crashes:(SNMCrashes *)crashes willSendErrorReport:(SNMErrorReport *)errorReport {
}

- (void)crashes:(SNMCrashes *)crashes didSucceedSendingErrorReport:(SNMErrorReport *)errorReport {
}

- (void)crashes:(SNMCrashes *)crashes didFailSendingErrorReport:(SNMErrorReport *)errorReport withError:(NSError *)error {
}

@end
