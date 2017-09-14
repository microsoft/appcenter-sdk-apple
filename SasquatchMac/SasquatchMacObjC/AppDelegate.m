#import "AppDelegate.h"
#import "MSAlertController.h"
#import "MobileCenterDelegateObjC.h"

@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;
@import MobileCenterPush;

static NSString *const kSMLogTag = @"[SasquatchMac]";

@implementation AppDelegate

- (instancetype)init {
  self = [super init];
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];
  [MSMobileCenter setLogUrl:@"https://in-integration.dev.avalanch.es"];

  // Customize services.
  [self setupCrashes];
  [self setupPush];

  // Start MobileCenter.
  [MSMobileCenter start:@"4b3f7d94-c64b-4aac-94f5-894c55c64bfe"
           withServices:@[ [MSAnalytics class], [MSCrashes class], [MSPush class] ]];
  [MobileCenterProvider shared].mobileCenter = [[MobileCenterDelegateObjC alloc] init];
  return self;
}

#pragma mark - Private

- (void)setupCrashes {
  if ([MSCrashes hasCrashedInLastSession]) {
    MSErrorReport *errorReport = [MSCrashes lastSessionCrashReport];
    NSLog(@"%@ We crashed with Signal: %@", kSMLogTag, errorReport.signal);
    MSDevice *device = [errorReport device];
    NSString *osVersion = [device osVersion];
    NSString *appVersion = [device appVersion];
    NSString *appBuild = [device appBuild];
    NSLog(@"%@ OS Version is: %@", kSMLogTag, osVersion);
    NSLog(@"%@ App Version is: %@", kSMLogTag, appVersion);
    NSLog(@"%@ App Build is: %@", kSMLogTag, appBuild);
  }

  [MSCrashes setDelegate:self];
  [MSCrashes setUserConfirmationHandler:(^(NSArray<MSErrorReport *> *errorReports) {

               // Use MSAlertViewController to show a dialog to the user where they can choose if they want to provide a
               // crash report.
               MSAlertController *alertController = [MSAlertController
                   alertControllerWithTitle:@"Sorry about that!"
                                    message:@"Do you want to send an anonymous crash report so we can fix the issue?"
                                      style:NSAlertStyleWarning];

               // Add a "Always"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationAlways
               [alertController addActionWithTitle:@"Always Send"
                                           handler:^() {
                                             [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];
                                           }];

               // Add a "Yes"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationSend
               [alertController addActionWithTitle:@"Send"
                                           handler:^() {
                                             [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
                                           }];

               // Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationDontSend
               [alertController addActionWithTitle:@"Don't Send"
                                           handler:^() {
                                             [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
                                           }];

               // Show the alert controller.
               [alertController show];

               return YES;
             })];
}

- (void)setupPush {
  [MSPush setDelegate:self];
  [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
}

#pragma mark - MSCrashesDelegate

- (BOOL)crashes:(MSCrashes *)crashes shouldProcessErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"%@ Should process error report with: %@", kSMLogTag, errorReport.exceptionReason);
  return YES;
}

- (void)crashes:(MSCrashes *)crashes willSendErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"%@ Will send error report with: %@", kSMLogTag, errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes didSucceedSendingErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"%@ Did succeed error report sending with: %@", kSMLogTag, errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes didFailSendingErrorReport:(MSErrorReport *)errorReport withError:(NSError *)error {
  NSLog(@"%@ Did fail sending report with: %@, and error: %@", kSMLogTag, errorReport.exceptionReason,
        error.localizedDescription);
}

#pragma mark - MSPushDelegate

- (void)application:(NSApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  NSLog(@"%@ Did register for remote notifications with device token.", kSMLogTag);
}

- (void)application:(NSApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error {
  NSLog(@"%@ Did fail to register for remote notifications with error %@.", kSMLogTag, [error localizedDescription]);
}

- (void)application:(NSApplication *)application didReceiveRemoteNotification:(NSDictionary<NSString *, id> *)userInfo {
  NSLog(@"%@ Did receive remote notification", kSMLogTag);
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification {
  NSLog(@"%@ Did receive user notification", kSMLogTag);
}

- (void)push:(MSPush *)push didReceivePushNotification:(MSPushNotification *)pushNotification {

  // Bring any window to foreground if it was miniaturized.
  for (NSWindow *window in [NSApp windows]) {
    if ([window isMiniaturized]) {
      [window deminiaturize:self];
      break;
    }
  }

  // Show alert for the notification.
  NSString *message = pushNotification.message;
  for (NSString *key in pushNotification.customData) {
    message = [NSString stringWithFormat:@"%@\n%@: %@", message, key, [pushNotification.customData objectForKey:key]];
  }
  MSAlertController *alertController = [MSAlertController
      alertControllerWithTitle:(pushNotification.title ? pushNotification.title : @"Push notification received")
                       message:message
                         style:NSAlertStyleInformational];
  [alertController addActionWithTitle:@"OK"
                              handler:^(){
                              }];

  // Show the alert controller.
  [alertController show];
}

@end
