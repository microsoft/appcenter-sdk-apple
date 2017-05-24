#import "AppDelegate.h"
#import "MobileCenterDelegateObjC.h"

@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];
  [MSMobileCenter setLogUrl:@"https://in-integration.dev.avalanch.es"];
  [MSMobileCenter start:@"8649b73e-6df0-4985-a039-8ab1453d44f3"
           withServices:@[ [MSAnalytics class], [MSCrashes class] ]];
  [self setMobileCenterDelegate];
}

- (void)setMobileCenterDelegate {
  SasquatchMacViewController *viewController = (SasquatchMacViewController *) [[[NSApplication sharedApplication] mainWindow] contentViewController];
  viewController.mobileCenter = [MobileCenterDelegateObjC new];
}

@end
