// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppDelegate.h"
#import "AppCenterDelegateObjC.h"
#import "Constants.h"

@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;

@interface AppDelegate ()

@property NSWindowController *rootController;
@property(nonatomic) CLLocationManager *locationManager;

@end

enum StartupMode { appCenter, oneCollector, both, none, skip };

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  [MSACAppCenter setLogLevel:MSACLogLevelVerbose];

  // Setup location manager.
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;
  self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;

  // Set custom log URL.
  NSString *logUrl = [[NSUserDefaults standardUserDefaults] objectForKey:kMSLogUrl];
  if (logUrl) {
    [MSACAppCenter setLogUrl:logUrl];
  }

  // Customize services.
  [self setupCrashes];

  // Set max storage size.
  NSNumber *storageMaxSize = [[NSUserDefaults standardUserDefaults] objectForKey:kMSStorageMaxSizeKey];
  if (storageMaxSize != nil) {
    [MSACAppCenter setMaxStorageSize:storageMaxSize.integerValue
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
  NSArray<Class> *services = @[ [MSACAnalytics class], [MSACCrashes class] ];
  NSInteger startTarget = [[NSUserDefaults standardUserDefaults] integerForKey:kMSStartTargetKey];
  NSString *appSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kMSAppSecret] ?: kMSObjcAppSecret;
  switch (startTarget) {
  case appCenter:
    [MSACAppCenter start:appSecret withServices:services];
    break;
  case oneCollector:
    [MSACAppCenter start:[NSString stringWithFormat:@"target=%@", kMSObjCTargetToken] withServices:services];
    break;
  case both:
    [MSACAppCenter start:[NSString stringWithFormat:@"appsecret=%@;target=%@", appSecret, kMSObjCTargetToken] withServices:services];
    break;
  case none:
    [MSACAppCenter startWithServices:services];
    break;
  }

  // Set user id.
  NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:kMSUserIdKey];
  if (userId) {
    [MSACAppCenter setUserId:userId];
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
    alert.messageText = NSLocalizedString(@"Location service is disabled", nil);
    alert.informativeText = NSLocalizedString(@"Please enable location service on your Mac.", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
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
  if ([MSACCrashes hasCrashedInLastSession]) {
    MSACErrorReport *errorReport = [MSACCrashes lastSessionCrashReport];
    NSLog(@"%@ We crashed with Signal: %@", kMSLogTag, errorReport.signal);
    MSACDevice *device = [errorReport device];
    NSString *osVersion = [device osVersion];
    NSString *appVersion = [device appVersion];
    NSString *appBuild = [device appBuild];
    NSLog(@"%@ OS Version is: %@", kMSLogTag, osVersion);
    NSLog(@"%@ App Version is: %@", kMSLogTag, appVersion);
    NSLog(@"%@ App Build is: %@", kMSLogTag, appBuild);
  }

  [MSACCrashes setDelegate:self];
  [MSACCrashes setUserConfirmationHandler:(^(NSArray<MSACErrorReport *> *errorReports) {
                 // Use MSAlertViewController to show a dialog to the user where they can choose if they want to provide a crash report.
                 NSAlert *alert = [[NSAlert alloc] init];
                 [alert setMessageText:NSLocalizedString(@"Sorry about that!", nil)];
                 [alert setInformativeText:NSLocalizedString(@"Do you want to send an anonymous crash "
                                                             @"report so we can fix the issue?",
                                                             nil)];
                 [alert addButtonWithTitle:NSLocalizedString(@"Always send", nil)];
                 [alert addButtonWithTitle:NSLocalizedString(@"Send", nil)];
                 [alert addButtonWithTitle:NSLocalizedString(@"Don't send", nil)];
                 [alert setAlertStyle:NSWarningAlertStyle];

                 switch ([alert runModal]) {
                 case NSAlertFirstButtonReturn:
                   [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationAlways];
                   break;
                 case NSAlertSecondButtonReturn:
                   [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationSend];
                   break;
                 case NSAlertThirdButtonReturn:
                   [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationDontSend];
                   break;
                 default:
                   break;
                 }

                 return YES;
               })];

  // Enable catching uncaught exceptions thrown on the main thread.
  [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"NSApplicationCrashOnExceptions" : @YES}];
}

#pragma mark - MSACCrashesDelegate

- (BOOL)crashes:(nonnull MSACCrashes *)crashes shouldProcessErrorReport:(nonnull MSACErrorReport *)errorReport {
  NSLog(@"%@ Should process error report with: %@", kMSLogTag, errorReport.exceptionReason);
  return YES;
}

- (void)crashes:(nonnull MSACCrashes *)crashes willSendErrorReport:(nonnull MSACErrorReport *)errorReport {
  NSLog(@"%@ Will send error report with: %@", kMSLogTag, errorReport.exceptionReason);
}

- (void)crashes:(nonnull MSACCrashes *)crashes didSucceedSendingErrorReport:(nonnull MSACErrorReport *)errorReport {
  NSLog(@"%@ Did succeed error report sending with: %@", kMSLogTag, errorReport.exceptionReason);
}

- (void)crashes:(nonnull MSACCrashes *)crashes
    didFailSendingErrorReport:(nonnull MSACErrorReport *)errorReport
                    withError:(nullable NSError *)error {
  NSLog(@"%@ Did fail sending report with: %@, and error: %@", kMSLogTag, errorReport.exceptionReason, error.localizedDescription);
}

- (NSArray<MSACErrorAttachmentLog *> *)attachmentsWithCrashes:(MSACCrashes *)crashes forErrorReport:(MSACErrorReport *)errorReport {
  NSMutableArray *attachments = [[NSMutableArray alloc] init];

  // Text attachment.
  NSString *text = [[NSUserDefaults standardUserDefaults] objectForKey:@"textAttachment"];
  if (text != nil && text.length > 0) {
    MSACErrorAttachmentLog *textAttachment = [MSACErrorAttachmentLog attachmentWithText:text filename:@"user.log"];
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
      MSACErrorAttachmentLog *binaryAttachment = [MSACErrorAttachmentLog attachmentWithBinary:data
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
                   [MSACAppCenter setCountryCode:placemark.ISOcountryCode];
                 }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  NSLog(@"Failed to find user's location: %@", error.localizedDescription);
}

@end
