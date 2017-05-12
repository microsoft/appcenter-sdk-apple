#import "AppDelegate.h"
#import "MobileCenterDelegateObjC.h"

@import MobileCenterMac;
@import MobileCenterAnalyticsMac;
@import MobileCenterCrashesMac;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [MSAnalytics setEnabled:[ServiceStateStore AnalyticsState]];
  [MSCrashes setEnabled:[ServiceStateStore CrashesState]];
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];
  [MSMobileCenter setLogUrl:@"https://in-integration.dev.avalanch.es"];
  [MSMobileCenter start:@"7ee5f412-02f7-45ea-a49c-b4ebf2911325"
           withServices:@[ [MSAnalytics class], [MSCrashes class] ]];
  [self setMobileCenterDelegate];
}

- (void)setMobileCenterDelegate {
  SasquatchMacViewController *viewController = (SasquatchMacViewController *) [[[NSApplication sharedApplication] mainWindow] contentViewController];
  viewController.mobileCenter = [MobileCenterDelegateObjC new];
}

@end
