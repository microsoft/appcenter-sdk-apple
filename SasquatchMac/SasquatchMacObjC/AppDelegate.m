#import "AppDelegate.h"

@import MobileCenterMac;
@import MobileCenterAnalyticsMac;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

  // Insert code here to initialize your application
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];
  [MSMobileCenter setLogUrl:@"https://in-integration.dev.avalanch.es"];
  [MSMobileCenter start:@"7ee5f412-02f7-45ea-a49c-b4ebf2911325"
           withServices:@[ [MSAnalytics class] ]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}

@end
