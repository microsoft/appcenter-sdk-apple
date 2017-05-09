#import "AppDelegate.h"

@import MobileCenterMac;
@import MobileCenterAnalyticsMac;
@import MobileCenterCrashesMac;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

  // Insert code here to initialize your application
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];
  [MSMobileCenter setLogUrl:@"https://in-integration.dev.avalanch.es"];
  [MSMobileCenter start:@"d7382cb6-a64d-4ef1-91a4-d32e885d3029"
           withServices:@[ [MSAnalytics class], [MSCrashes class] ]];
}

@end
