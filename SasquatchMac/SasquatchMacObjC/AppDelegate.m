// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppDelegate.h"
#import "AppCenterDelegateObjC.h"
#import "Constants.h"

@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;
@import AppCenterPush;

@interface AppDelegate ()

@property NSWindowController *rootController;
@property(nonatomic) CLLocationManager *locationManager;

@end

enum StartupMode { appCenter, oneCollector, both, none, skip };

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  [MSAppCenter setLogLevel:MSLogLevelVerbose];

  // Setup location manager.
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;
  self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;

  // Set custom log URL.
  NSString *logUrl = [[NSUserDefaults standardUserDefaults] objectForKey:kMSLogUrl];
  if (logUrl) {
    [MSAppCenter setLogUrl:logUrl];
  }

  // Customize services.
  [self setupCrashes];
  [self setupPush];

  // Set max storage size.
  NSNumber *storageMaxSize = [[NSUserDefaults standardUserDefaults] objectForKey:kMSStorageMaxSizeKey];
  if (storageMaxSize) {
    [MSAppCenter setMaxStorageSize:storageMaxSize.integerValue
                 completionHandler:^(BOOL success) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                     if (success) {
                       long realStorageSize = (long)(ceil([storageMaxSize doubleValue] / kMSStoragePageSize) * kMSStoragePageSize);
                       [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:realStorageSize]
                                                                 forKey:kMSStorageMaxSizeKey];
                     } else {

                       // Remove invalid value.
                       [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMSStorageMaxSizeKey];
                     }
                   });
                 }];
  }

  // Start AppCenter.
  NSArray<Class> *services = @ [[MSAnalytics class], [MSCrashes class], [MSPush class]];
  NSInteger startTarget = [[NSUserDefaults standardUserDefaults] integerForKey:kMSStartTargetKey];
  NSString *appSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kMSAppSecret] ?: kMSObjcAppSecret;
  switch (startTarget) {
  case appCenter:
    [MSAppCenter start:appSecret withServices:services];
    break;
  case oneCollector:
    [MSAppCenter start:[NSString stringWithFormat:@"target=%@", kMSObjCTargetToken] withServices:services];
    break;
  case both:
    [MSAppCenter start:[NSString stringWithFormat:@"appsecret=%@;target=%@", appSecret, kMSObjCTargetToken] withServices:services];
    break;
  case none:
    [MSAppCenter startWithServices:services];
    break;
  }

  // Set user id.
  NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:kMSUserIdKey];
  if (userId) {
    [MSAppCenter setUserId:userId];
  }
    
  [AppCenterProvider shared].appCenter = [[AppCenterDelegateObjC alloc] init];
  [self initUI];
  [self overrideCountryCode];
}

- (void)overrideCountryCode {
  if ([CLLocationManager locationServicesEnabled]) {
    [self.locationManager startUpdatingLocation];
  } else {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Location service is disabled";
    alert.informativeText = @"Please enable location service on your Mac.";
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
  }
}

#pragma mark - Private

- (void)initUI {
  NSStoryboard *mainStoryboard = [NSStoryboard storyboardWithName:kMSMainStoryboardName bundle:nil];
  self.rootController = (NSWindowController *)[mainStoryboard instantiateControllerWithIdentifier:@"rootController"];
  [self.rootController showWindow:self];
  [self.rootController.window makeKeyAndOrderFront:self];
}

- (void)setupCrashes {
  if ([MSCrashes hasCrashedInLastSession]) {
    MSErrorReport *errorReport = [MSCrashes lastSessionCrashReport];
    NSLog(@"%@ We crashed with Signal: %@", kMSLogTag, errorReport.signal);
    MSDevice *device = [errorReport device];
    NSString *osVersion = [device osVersion];
    NSString *appVersion = [device appVersion];
    NSString *appBuild = [device appBuild];
    NSLog(@"%@ OS Version is: %@", kMSLogTag, osVersion);
    NSLog(@"%@ App Version is: %@", kMSLogTag, appVersion);
    NSLog(@"%@ App Build is: %@", kMSLogTag, appBuild);
  }

  [MSCrashes setDelegate:self];
  [MSCrashes setUserConfirmationHandler:(^(NSArray<MSErrorReport *> *errorReports) {
               // Use MSAlertViewController to show a dialog to the user where they can choose if they want to provide a crash report.
               NSAlert *alert = [[NSAlert alloc] init];
               [alert setMessageText:@"Sorry about that!"];
               [alert setInformativeText:@"Do you want to send an anonymous crash "
                                         @"report so we can fix the issue?"];
               [alert addButtonWithTitle:@"Always send"];
               [alert addButtonWithTitle:@"Send"];
               [alert addButtonWithTitle:@"Don't send"];
               [alert setAlertStyle:NSWarningAlertStyle];

               switch ([alert runModal]) {
               case NSAlertFirstButtonReturn:
                 [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];
                 break;
               case NSAlertSecondButtonReturn:
                 [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
                 break;
               case NSAlertThirdButtonReturn:
                 [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
                 break;
               default:
                 break;
               }

               return YES;
             })];

  // Enable catching uncaught exceptions thrown on the main thread.
  [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"NSApplicationCrashOnExceptions" : @YES}];
}

- (void)setupPush {
  [MSPush setDelegate:self];
  [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
}

#pragma mark - MSCrashesDelegate

- (BOOL)crashes:(MSCrashes *)crashes shouldProcessErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"%@ Should process error report with: %@", kMSLogTag, errorReport.exceptionReason);
  return YES;
}

- (void)crashes:(MSCrashes *)crashes willSendErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"%@ Will send error report with: %@", kMSLogTag, errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes didSucceedSendingErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"%@ Did succeed error report sending with: %@", kMSLogTag, errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes didFailSendingErrorReport:(MSErrorReport *)errorReport withError:(NSError *)error {
  NSLog(@"%@ Did fail sending report with: %@, and error: %@", kMSLogTag, errorReport.exceptionReason, error.localizedDescription);
}

- (NSArray<MSErrorAttachmentLog *> *)attachmentsWithCrashes:(MSCrashes *)crashes forErrorReport:(MSErrorReport *)errorReport {
  NSMutableArray *attachments = [[NSMutableArray alloc] init];

  // Text attachment.
  NSString *text = [[NSUserDefaults standardUserDefaults] objectForKey:@"textAttachment"];
  if (text != nil && text.length > 0) {
    MSErrorAttachmentLog *textAttachment = [MSErrorAttachmentLog attachmentWithText:text filename:@"user.log"];
    [attachments addObject:textAttachment];
  }

  // Binary attachment.
  NSURL *referenceUrl = [[NSUserDefaults standardUserDefaults] URLForKey:@"fileAttachment"];
  if (referenceUrl) {
    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL:referenceUrl options:0 error:&error];
    if (data && !error) {
      CFStringRef UTI =
          UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[referenceUrl pathExtension], nil);
      NSString *MIMEType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
      CFRelease(UTI);
      MSErrorAttachmentLog *binaryAttachment = [MSErrorAttachmentLog attachmentWithBinary:data
                                                                                 filename:referenceUrl.lastPathComponent
                                                                              contentType:MIMEType];
      [attachments addObject:binaryAttachment];
      NSLog(@"Add binary attachment with %tu bytes", [data length]);
    } else {
      NSLog(@"Couldn't read attachment file with error: %@", error.localizedDescription);
    }
  }
  return attachments;
}

#pragma mark - MSPushDelegate

- (void)application:(NSApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  NSLog(@"%@ Did register for remote notifications with device token.", kMSLogTag);
}

- (void)application:(NSApplication *)application didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error {
  NSLog(@"%@ Did fail to register for remote notifications with error %@.", kMSLogTag, [error localizedDescription]);
}

- (void)application:(NSApplication *)application didReceiveRemoteNotification:(NSDictionary<NSString *, id> *)userInfo {
  NSLog(@"%@ Did receive remote notification", kMSLogTag);
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
  NSLog(@"%@ Did receive user notification", kMSLogTag);
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
  NSString *title = pushNotification.title ?: @"";
  NSString *message = pushNotification.message;
  NSMutableString *customData = nil;
  for (NSString *key in pushNotification.customData) {
    ([customData length] == 0) ? customData = [NSMutableString new] : [customData appendString:@", "];
    [customData appendFormat:@"%@: %@", key, [pushNotification.customData objectForKey:key]];
  }
  message = [NSString
      stringWithFormat:@"%@%@%@", (message ? message : @""), (message && customData ? @"\n" : @""), (customData ? customData : @"")];
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:title];
  [alert setInformativeText:message];
  [alert addButtonWithTitle:@"OK"];
  [alert runModal];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
  [self.locationManager stopUpdatingLocation];
  CLLocation *location = [locations lastObject];
  CLGeocoder *geocoder = [[CLGeocoder alloc] init];
  [geocoder reverseGeocodeLocation:location
                 completionHandler:^(NSArray *placemarks, NSError *error) {
                   if (placemarks.count == 0 || error)
                     return;
                   CLPlacemark *placemark = [placemarks firstObject];
                   [MSAppCenter setCountryCode:placemark.ISOcountryCode];
                 }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  NSLog(@"Failed to find user's location: %@", error.localizedDescription);
}

@end
