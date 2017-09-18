/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <UserNotifications/UserNotifications.h>
#import "AppDelegate.h"
#import "Constants.h"
#import "EventLog.h"
#import "MSErrorAttachmentLog.h"
#import "MSErrorAttachmentLog+Utility.h"
#import "MobileCenter.h"
#import "MobileCenterAnalytics.h"
#import "MobileCenterCrashes.h"
#import "MobileCenterDistribute.h"
#import "MobileCenterPush.h"
#import "MSAlertController.h"
#import "MSAnalyticsDelegate.h"
#import "MSAnalyticsInternal.h"
#import "MSEventLog.h"

static UIViewController *crashResultViewController = nil;

@interface AppDelegate () <MSCrashesDelegate, MSDistributeDelegate, MSPushDelegate, MSAnalyticsDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // View controller should register in NSNotificationCenter before SDK start.
  crashResultViewController =
      [[[[self window] rootViewController] storyboard] instantiateViewControllerWithIdentifier:@"crashResult"];

  // Customize Mobile Center SDK.
  [MSDistribute setDelegate:self];
  [MSPush setDelegate:self];
  [MSAnalytics setDelegate:self];
  [MSMobileCenter setLogLevel:MSLogLevelVerbose];

  // Start Mobile Center SDK.
  [MSMobileCenter start:@"7dfb022a-17b5-4d4a-9c75-12bc3ef5e6b7"
           withServices:@[ [MSAnalytics class], [MSCrashes class], [MSDistribute class], [MSPush class] ]];

  [self crashes];

  // Print the install Id.
  NSLog(@"%@ Install Id: %@", kPUPLogTag, [[MSMobileCenter installId] UUIDString]);
  return YES;
}

#pragma mark - URL handling

// Open URL for iOS 8.
- (BOOL)application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation {
  NSLog(@"%@ Was woken up via openURL:sourceApplication:annotation: %@.", kPUPLogTag, url);
  return NO;
}

// Open URL for iOS 9+.
- (BOOL)application:(UIApplication *)application
            openURL:(nonnull NSURL *)url
            options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  NSLog(@"%@ Was waken up via openURL:options: %@.", kPUPLogTag, url);
  return NO;
}

#pragma mark - Application life cycle

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  NSLog(@"%@ Did register for remote notifications with device token.", kPUPLogTag);
}

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error {
  NSLog(@"%@ Did fail to register for remote notifications with error %@.", kPUPLogTag, [error localizedDescription]);
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  BOOL result = [MSPush didReceiveRemoteNotification:userInfo];
  if (result) {
    completionHandler(UIBackgroundFetchResultNewData);
  } else {
    completionHandler(UIBackgroundFetchResultNoData);
  }
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
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
        [NSNotificationCenter.defaultCenter postNotificationName:kDidShouldAwaitUserConfirmationEvent object:nil];

        // Show a dialog to the user where they can choose if they want to provide a crash report.
        MSAlertController *alertController = [MSAlertController
            alertControllerWithTitle:NSLocalizedStringFromTable(@"crash_alert_title", @"Main", @"")
                             message:NSLocalizedStringFromTable(@"crash_alert_message", @"Main", @"")];

        // Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationDontSend
        [alertController addCancelActionWithTitle:NSLocalizedStringFromTable(@"crash_alert_do_not_send", @"Main", @"")
                                          handler:^(UIAlertAction *action) {
                                            [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
                                          }];

        // Add a "Yes"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationSend
        [alertController addDefaultActionWithTitle:NSLocalizedStringFromTable(@"crash_alert_send", @"Main", @"")
                                           handler:^(UIAlertAction *action) {
                                             [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
                                           }];

        // Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationAlways
        [alertController addDefaultActionWithTitle:NSLocalizedStringFromTable(@"crash_alert_always_send", @"Main", @"")
                                           handler:^(UIAlertAction *action) {
                                             [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];
                                           }];
        // Show the alert controller.
        [alertController show];

        return YES;
      })];
}

#pragma mark - MSCrashesDelegate

- (BOOL)crashes:(MSCrashes *)crashes shouldProcessErrorReport:(MSErrorReport *)errorReport {
  [NSNotificationCenter.defaultCenter postNotificationName:kShouldProcessErrorReportEvent object:nil];
  NSLog(@"Should process error report with: %@", errorReport.exceptionReason);
  return YES;
}

- (void)crashes:(MSCrashes *)crashes willSendErrorReport:(MSErrorReport *)errorReport {
  [NSNotificationCenter.defaultCenter postNotificationName:kWillSendErrorReportEvent object:nil];
  NSLog(@"Will send error report with: %@", errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes didSucceedSendingErrorReport:(MSErrorReport *)errorReport {
  [NSNotificationCenter.defaultCenter postNotificationName:kDidSucceedSendingErrorReportEvent object:nil];
  NSLog(@"Did succeed error report sending with: %@", errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes didFailSendingErrorReport:(MSErrorReport *)errorReport withError:(NSError *)error {
  [NSNotificationCenter.defaultCenter postNotificationName:kDidFailSendingErrorReportEvent object:nil];
  NSLog(@"Did fail sending report with: %@, and error: %@", errorReport.exceptionReason, error.localizedDescription);
}

- (NSArray<MSErrorAttachmentLog *> *)attachmentsWithCrashes:(MSCrashes *)crashes
                                             forErrorReport:(MSErrorReport *)errorReport {
  NSData *data = [[NSString stringWithFormat:@"<xml><text>Binary attachment for crash</text><id>%@</id></xml>",
                                             errorReport.incidentIdentifier] dataUsingEncoding:NSUTF8StringEncoding];
  NSString *text = [NSString stringWithFormat:@"Text attachement for crash #%@", errorReport.incidentIdentifier];
  MSErrorAttachmentLog *attachment1 =
      [MSErrorAttachmentLog attachmentWithText:text filename:@"pup-crash-attachment.log"];
  MSErrorAttachmentLog *attachment2 =
      [MSErrorAttachmentLog attachmentWithBinary:data filename:nil contentType:@"text/xml"];
  return @[ attachment1, attachment2 ];
}

#pragma mark - MSDistributeDelegate

- (BOOL)distribute:(MSDistribute *)distribute releaseAvailableWithDetails:(MSReleaseDetails *)details {
  if ([[[NSUserDefaults new] objectForKey:kPUPCustomizedUpdateAlertKey] isEqual:@1]) {

    // Show a dialog to the user where they can choose if they want to update.
    MSAlertController *alertController = [MSAlertController
        alertControllerWithTitle:NSLocalizedStringFromTable(@"distribute_alert_title", @"Main", @"")
                         message:NSLocalizedStringFromTable(@"distribute_alert_message", @"Main", @"")];

    // Add a "Yes"-Button and call the notifyUpdateAction-callback with MSUpdateActionUpdate
    [alertController addCancelActionWithTitle:NSLocalizedStringFromTable(@"distribute_alert_yes", @"Main", @"")
                                      handler:^(UIAlertAction *action) {
                                        [MSDistribute notifyUpdateAction:MSUpdateActionUpdate];
                                      }];

    // Add a "No"-Button and call the notifyUpdateAction-callback with MSUpdateActionPostpone
    [alertController addDefaultActionWithTitle:NSLocalizedStringFromTable(@"distribute_alert_no", @"Main", @"")
                                       handler:^(UIAlertAction *action) {
                                         [MSDistribute notifyUpdateAction:MSUpdateActionPostpone];
                                       }];

    // Show the alert controller.
    [alertController show];
    return YES;
  }
  return NO;
}

#pragma mark - MSPushDelegate

- (void)push:(MSPush *)push didReceivePushNotification:(MSPushNotification *)pushNotification {
  NSString *title = pushNotification.title;
  NSString *message = pushNotification.message;
  NSMutableString *customData = nil;
  for (NSString *key in pushNotification.customData) {
    ([customData length] == 0) ? customData = [NSMutableString new] : [customData appendString:@", "];
    [customData appendFormat:@"%@: %@", key, [pushNotification.customData objectForKey:key]];
  }
  if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
    NSLog(@"%@ Notification received in background, title: \"%@\", message: \"%@\", custom data: \"%@\"", kPUPLogTag,
          title, message, customData);
  } else {
    message = [NSString stringWithFormat:@"%@%@%@", (message ? message : @""), (message && customData ? @"\n" : @""),
                                         (customData ? customData : @"")];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
  }
}

#pragma mark - MSAnalyticsDelegate

- (void)analytics:(MSAnalytics *)analytics willSendEventLog:(MSEventLog *)eventLog {
  [NSNotificationCenter.defaultCenter postNotificationName:kWillSendEventLog object:[self msLogEventToLocal:eventLog]];
}

- (void)analytics:(MSAnalytics *)analytics didSucceedSendingEventLog:(MSEventLog *)eventLog {
  [NSNotificationCenter.defaultCenter postNotificationName:kDidSucceedSendingEventLog
                                                    object:[self msLogEventToLocal:eventLog]];
}

- (void)analytics:(MSAnalytics *)analytics didFailSendingEventLog:(MSEventLog *)eventLog withError:(NSError *)error {
  [NSNotificationCenter.defaultCenter postNotificationName:kDidFailSendingEventLog
                                                    object:[self msLogEventToLocal:eventLog]];
}

- (EventLog *)msLogEventToLocal:(MSEventLog *)msLog {
  EventLog *log = [EventLog new];
  log.eventName = msLog.name;
  if (!msLog.properties) {
    return log;
  }

  // Collect props
  for (NSString *key in msLog.properties) {
    NSString *value = [msLog.properties objectForKey:key];
    [log.properties setObject:value forKey:key];
  }
  return log;
}

#pragma mark - Public

+ (UIViewController *)crashResultViewController {
  return crashResultViewController;
}

@end
