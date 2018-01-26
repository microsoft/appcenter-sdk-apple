/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <UserNotifications/UserNotifications.h>

#import "AppDelegate.h"
#import "Constants.h"
#import "EventLog.h"

#import "MSAlertController.h"
#import "MSAnalytics.h"
#import "MSAnalyticsDelegate.h"
#import "MSAnalyticsInternal.h"
#import "MSAppCenter.h"
#import "MSCrashes.h"
#import "MSCrashesDelegate.h"
#import "MSDevice.h"
#import "MSDistribute.h"
#import "MSErrorAttachmentLog.h"
#import "MSErrorAttachmentLog+Utility.h"
#import "MSEventLog.h"
#import "MSLogWithPropertiesInternal.h"
#import "MSPush.h"
#import "MSPushNotification.h"

static UIViewController *crashResultViewController = nil;

@interface AppDelegate () <MSCrashesDelegate, MSDistributeDelegate, MSPushDelegate, MSAnalyticsDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // View controller should register in NSNotificationCenter before SDK start.
  crashResultViewController =
      [[[[self window] rootViewController] storyboard] instantiateViewControllerWithIdentifier:@"crashResult"];

  // Customize App Center SDK.
  [MSDistribute setDelegate:self];
  [MSPush setDelegate:self];
  [MSAnalytics setDelegate:self];
  [MSAppCenter setLogLevel:MSLogLevelVerbose];

  // Start Mobile Center SDK.
  [MSAppCenter start:@"7dfb022a-17b5-4d4a-9c75-12bc3ef5e6b7"
           withServices:@[ [MSAnalytics class], [MSCrashes class], [MSDistribute class], [MSPush class] ]];

  [self crashes];

  // Print the install Id.
  NSLog(@"%@ Install Id: %@", kPUPLogTag, [[MSAppCenter installId] UUIDString]);
  return YES;
}

#pragma mark - URL handling

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
  NSLog(@"%@ Did receive or did click notification with userInfo: %@.", kPUPLogTag, userInfo);
  completionHandler(UIBackgroundFetchResultNoData);
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
            alertControllerWithTitle:NSLocalizedStringFromTable(@"crash_alert_title", @"Puppet", @"")
                             message:NSLocalizedStringFromTable(@"crash_alert_message", @"Puppet", @"")];

        // Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationDontSend
        [alertController addCancelActionWithTitle:NSLocalizedStringFromTable(@"crash_alert_do_not_send", @"Puppet", @"")
                                          handler:^(UIAlertAction *action) {
                                            [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
                                          }];

        // Add a "Yes"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationSend
        [alertController addDefaultActionWithTitle:NSLocalizedStringFromTable(@"crash_alert_send", @"Puppet", @"")
                                           handler:^(UIAlertAction *action) {
                                             [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
                                           }];

        // Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationAlways
        [alertController addDefaultActionWithTitle:NSLocalizedStringFromTable(@"crash_alert_always_send", @"Puppet", @"")
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
  NSMutableArray *attachments = [[NSMutableArray alloc] init];
  
  // Text attachment.
  NSString *text = [[NSUserDefaults standardUserDefaults] objectForKey:@"textAttachment"];
  if (text != nil && text.length > 0) {
    MSErrorAttachmentLog *textAttachment = [MSErrorAttachmentLog attachmentWithText:text
                                                                           filename:@"user.log"];
    [attachments addObject:textAttachment];
  }
  
  // Binary attachment.
  NSURL *referenceUrl = [[NSUserDefaults standardUserDefaults] URLForKey:@"fileAttachment"];
  if (referenceUrl) {
    PHAsset *asset = [[PHAsset fetchAssetsWithALAssetURLs:@[referenceUrl] options:nil] lastObject];
    if (asset) {
      PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
      options.synchronous = YES;
      [[PHImageManager defaultManager]
          requestImageDataForAsset:asset
                           options:options
                     resultHandler:^(NSData *_Nullable imageData, NSString *_Nullable dataUTI,
                                     __unused UIImageOrientation orientation, __unused NSDictionary *_Nullable info) {
                       CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[dataUTI pathExtension], nil);
                       NSString *MIMEType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
                       CFRelease(UTI);
                       MSErrorAttachmentLog *binaryAttachment = [MSErrorAttachmentLog attachmentWithBinary:imageData filename:dataUTI contentType:MIMEType];
                       [attachments addObject:binaryAttachment];
                       NSLog(@"Add binary attachment with %lu bytes", [imageData length]);
                     }];
    }
  }
  return attachments;
}

#pragma mark - MSDistributeDelegate

- (BOOL)distribute:(MSDistribute *)distribute releaseAvailableWithDetails:(MSReleaseDetails *)details {
  if ([[[NSUserDefaults new] objectForKey:kPUPCustomizedUpdateAlertKey] isEqual:@1]) {

    // Show a dialog to the user where they can choose if they want to update.
    MSAlertController *alertController = [MSAlertController
        alertControllerWithTitle:NSLocalizedStringFromTable(@"distribute_alert_title", @"Puppet", @"")
                         message:NSLocalizedStringFromTable(@"distribute_alert_message", @"Puppet", @"")];

    // Add a "Yes"-Button and call the notifyUpdateAction-callback with MSUpdateActionUpdate
    [alertController addCancelActionWithTitle:NSLocalizedStringFromTable(@"distribute_alert_yes", @"Puppet", @"")
                                      handler:^(UIAlertAction *action) {
                                        [MSDistribute notifyUpdateAction:MSUpdateActionUpdate];
                                      }];

    // Add a "No"-Button and call the notifyUpdateAction-callback with MSUpdateActionPostpone
    [alertController addDefaultActionWithTitle:NSLocalizedStringFromTable(@"distribute_alert_no", @"Puppet", @"")
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
    
    MSAlertController *alertController = [MSAlertController
                                          alertControllerWithTitle:title
                                          message:message];
    [alertController addCancelActionWithTitle:@"OK"
                                      handler:nil];
    
    // Show the alert controller.
    [alertController show];
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

