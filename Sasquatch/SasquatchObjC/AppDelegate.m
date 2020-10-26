// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <UserNotifications/UserNotifications.h>

#if GCC_PREPROCESSOR_MACRO_PUPPET
#import "AppCenter.h"
#import "AppCenterAnalytics.h"
#import "AppCenterCrashes.h"
#if !TARGET_OS_MACCATALYST
#import "AppCenterDistribute.h"
#endif

// Internal ones
#import "MSACAnalyticsInternal.h"

#elif GCC_PREPROCESSOR_MACRO_SASQUATCH_OBJC
#import <AppCenter/AppCenter.h>
#import <AppCenterAnalytics/AppCenterAnalytics.h>
#import <AppCenterCrashes/AppCenterCrashes.h>
#import <AppCenterDistribute/AppCenterDistribute.h>
#else
@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;
@import AppCenterDistribute;
#endif

#import "AppCenterDelegateObjC.h"
#import "AppDelegate.h"
#import "Constants.h"

enum StartupMode { APPCENTER, ONECOLLECTOR, BOTH, NONE, SKIP };

@interface AppDelegate () <
#if GCC_PREPROCESSOR_MACRO_PUPPET
    MSACAnalyticsDelegate,
#endif
#if !TARGET_OS_MACCATALYST
    MSACDistributeDelegate,
#endif
    MSACCrashesDelegate, CLLocationManagerDelegate>

@property(nonatomic) MSAnalyticsResult *analyticsResult;
@property(nonatomic) CLLocationManager *locationManager;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [MSACAppCenter setLogLevel:MSACLogLevelVerbose];
  NSInteger startTarget = [[NSUserDefaults standardUserDefaults] integerForKey:kMSStartTargetKey];
#if GCC_PREPROCESSOR_MACRO_PUPPET
  self.analyticsResult = [MSAnalyticsResult new];
  [MSACAnalytics setDelegate:self];

  for (UIViewController *controller in [(UITabBarController *)self.window.rootViewController viewControllers]) {
    if ([controller isKindOfClass:[MSAnalyticsViewController class]]) {
      [(MSAnalyticsViewController *)controller setAnalyticsResult:self.analyticsResult];
    }
  }
  if (startTarget == APPCENTER || startTarget == BOTH) {
    [MSACAppCenter setLogUrl:kMSIntLogUrl];
  }
#if !TARGET_OS_MACCATALYST
  [MSACDistribute setApiUrl:kMSIntApiUrl];
  [MSACDistribute setInstallUrl:kMSIntInstallUrl];
#endif
#endif

// Customize App Center SDK.
#pragma clang diagnostic ignored "-Wpartial-availability"
#pragma clang diagnostic pop
#if !TARGET_OS_MACCATALYST
  [MSACDistribute setDelegate:self];
#endif
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

                       // Show alert.
                       UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning!", nil)
                                                                                                message:NSLocalizedString(@"The maximum size of the internal "
                                                                                                        @"storage could not be set.", nil)
                                                                                         preferredStyle:UIAlertControllerStyleAlert];
                       [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
                       [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
                     }
                   });
                 }];
  }

  NSString *logUrl = [[NSUserDefaults standardUserDefaults] objectForKey:kMSLogUrl];
  if (logUrl) {
    [MSACAppCenter setLogUrl:logUrl];
  }
  int latencyTimeValue = [[[NSUserDefaults standardUserDefaults] objectForKey:kMSTransmissionIterval] intValue];
  if (latencyTimeValue) {
    [MSACAnalytics setTransmissionInterval:latencyTimeValue];
  }
#if !TARGET_OS_MACCATALYST
  int updateTrack = [[[NSUserDefaults standardUserDefaults] objectForKey:kMSUpdateTrackKey] intValue];
  if (updateTrack) {
    MSACDistribute.updateTrack = updateTrack;
  }
  if ([[[NSUserDefaults standardUserDefaults] objectForKey:kSASAutomaticCheckForUpdateDisabledKey] isEqual:@1]) {
    [MSACDistribute disableAutomaticCheckForUpdate];
  }
#endif
  
  // Start App Center SDK.
#if !TARGET_OS_MACCATALYST
  NSArray<Class> *services = @ [[MSACAnalytics class], [MSACCrashes class], [MSACDistribute class]];
#else
  NSArray<Class> *services = @ [[MSACAnalytics class], [MSACCrashes class]];
#endif
#if GCC_PREPROCESSOR_MACRO_PUPPET
  NSString *appSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kMSAppSecret] ?: kMSPuppetAppSecret;
#else
  NSString *appSecret = [[NSUserDefaults standardUserDefaults] objectForKey:kMSAppSecret] ?: kMSObjcAppSecret;
#endif
  switch (startTarget) {
  case APPCENTER:
    [MSACAppCenter start:appSecret withServices:services];
    break;
  case ONECOLLECTOR:
    [MSACAppCenter start:[NSString stringWithFormat:@"target=%@", kMSObjCTargetToken] withServices:services];
    break;
  case BOTH:
    [MSACAppCenter start:[NSString stringWithFormat:@"%@;target=%@", appSecret, kMSObjCTargetToken] withServices:services];
    break;
  case NONE:
    [MSACAppCenter startWithServices:services];
    break;
  }

  // Setup location manager.
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;
  self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
  [self.locationManager requestWhenInUseAuthorization];

  // Set user id.
  NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:kMSUserIdKey];
  if (userId) {
    [MSACAppCenter setUserId:userId];
  }

  // Set delegates.
  [self crashes];
  [self setAppCenterDelegate];
  return YES;
}

- (void)requestLocation {
  if (CLLocationManager.locationServicesEnabled) {
    [self.locationManager requestLocation];
  }
}

#pragma mark - Application life cycle

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
  if ([MSACCrashes hasCrashedInLastSession]) {
    MSACErrorReport *errorReport = [MSACCrashes lastSessionCrashReport];
    NSLog(@"We crashed with Signal: %@", errorReport.signal);
    MSACDevice *device = [errorReport device];
    NSString *osVersion = [device osVersion];
    NSString *appVersion = [device appVersion];
    NSString *appBuild = [device appBuild];
    NSLog(@"OS Version is: %@", osVersion);
    NSLog(@"App Version is: %@", appVersion);
    NSLog(@"App Build is: %@", appBuild);
  }

  [MSACCrashes setDelegate:self];
  [MSACCrashes setUserConfirmationHandler:(^(NSArray<MSACErrorReport *> *errorReports) {
               // Use MSAlertViewController to show a dialog to the user where they can choose if they want to provide a crash report.
               UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sorry about that!", nil)
                                                                                        message:NSLocalizedString(@"Do you want to send an anonymous crash "
                                                                                                @"report so we can fix the issue?", nil)
                                                                                 preferredStyle:UIAlertControllerStyleAlert];

               // Add a "Don't send"-Button and call the notifyWithUserConfirmation-callback with MSACUserConfirmationDontSend
               [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Don't send", nil)
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction *action) {
                                                                   [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationDontSend];
                                                                 }]];

               // Add a "Send"-Button and call the notifyWithUserConfirmation-callback with MSACUserConfirmationSend
               [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Send", nil)
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                   [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationSend];
                                                                 }]];

               // Add a "Always send"-Button and call the notifyWithUserConfirmation-callback with MSACUserConfirmationAlways
               [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Always send", nil)
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                   [MSACCrashes notifyWithUserConfirmation:MSACUserConfirmationAlways];
                                                                 }]];

               // Show the alert controller.
               [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];

               return YES;
             })];
}

- (void)setAppCenterDelegate {
  AppCenterDelegateObjC *appCenterDel = [[AppCenterDelegateObjC alloc] init];
  for (UIViewController *controller in [(UITabBarController *)self.window.rootViewController viewControllers]) {
    if ([controller conformsToProtocol:@protocol(AppCenterProtocol)]) {
      id<AppCenterProtocol> sasquatchController = (id<AppCenterProtocol>)controller;
      sasquatchController.appCenter = appCenterDel;
    } else {
      [controller removeFromParentViewController];
    }
  }
}

#if GCC_PREPROCESSOR_MACRO_PUPPET
#pragma mark - MSACAnalyticsDelegate

- (void)analytics:(MSACAnalytics *)analytics willSendEventLog:(MSACEventLog *)eventLog {
  [self.analyticsResult willSendWithEventLog:eventLog];
  [NSNotificationCenter.defaultCenter postNotificationName:kUpdateAnalyticsResultNotification object:self.analyticsResult];
}

- (void)analytics:(MSACAnalytics *)analytics didSucceedSendingEventLog:(MSACEventLog *)eventLog {
  [self.analyticsResult didSucceedSendingWithEventLog:eventLog];
  [NSNotificationCenter.defaultCenter postNotificationName:kUpdateAnalyticsResultNotification object:self.analyticsResult];
}

- (void)analytics:(MSACAnalytics *)analytics didFailSendingEventLog:(MSACEventLog *)eventLog withError:(NSError *)error {
  [self.analyticsResult didFailSendingWithEventLog:eventLog withError:error];
  [NSNotificationCenter.defaultCenter postNotificationName:kUpdateAnalyticsResultNotification object:self.analyticsResult];
}
#endif

#pragma mark - MSACCrashesDelegate

- (BOOL)crashes:(MSACCrashes *)crashes shouldProcessErrorReport:(MSACErrorReport *)errorReport {
  NSLog(@"Should process error report with: %@", errorReport.exceptionReason);
  return YES;
}

- (void)crashes:(MSACCrashes *)crashes willSendErrorReport:(MSACErrorReport *)errorReport {
  NSLog(@"Will send error report with: %@", errorReport.exceptionReason);
}

- (void)crashes:(MSACCrashes *)crashes didSucceedSendingErrorReport:(MSACErrorReport *)errorReport {
  NSLog(@"Did succeed error report sending with: %@", errorReport.exceptionReason);
}

- (void)crashes:(MSACCrashes *)crashes didFailSendingErrorReport:(MSACErrorReport *)errorReport withError:(NSError *)error {
  NSLog(@"Did fail sending report with: %@, and error: %@", errorReport.exceptionReason, error.localizedDescription);
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
#if !TARGET_OS_MACCATALYST
    PHAsset *asset = [[PHAsset fetchAssetsWithALAssetURLs:@[ referenceUrl ] options:nil] lastObject];
    if (asset) {
      PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
      options.synchronous = YES;
      [[PHImageManager defaultManager]
          requestImageDataForAsset:asset
                           options:options
                     resultHandler:^(NSData *_Nullable imageData, NSString *_Nullable dataUTI, __unused UIImageOrientation orientation,
                                     __unused NSDictionary *_Nullable info) {
                       CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                               (__bridge CFStringRef)[dataUTI pathExtension], nil);
                       NSString *MIMEType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
                       CFRelease(UTI);
                       MSACErrorAttachmentLog *binaryAttachment = [MSACErrorAttachmentLog attachmentWithBinary:imageData
                                                                                                  filename:dataUTI
                                                                                               contentType:MIMEType];
                       [attachments addObject:binaryAttachment];
                       NSLog(@"Add binary attachment with %tu bytes", [imageData length]);
                     }];
    }
#else
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
#endif
  }
  return attachments;
}

#pragma mark - MSACDistributeDelegate

#if !TARGET_OS_MACCATALYST

- (BOOL)distribute:(MSACDistribute *)distribute releaseAvailableWithDetails:(MSACReleaseDetails *)details {

  if ([[[NSUserDefaults standardUserDefaults] objectForKey:kSASCustomizedUpdateAlertKey] isEqual:@1]) {

    // Show a dialog to the user where they can choose if they want to update.
    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"distribute_alert_title", @"Sasquatch", @"")
                                            message:NSLocalizedStringFromTable(@"distribute_alert_message", @"Sasquatch", @"")
                                     preferredStyle:UIAlertControllerStyleAlert];

    // Add a "Yes"-Button and call the notifyUpdateAction-callback with MSUpdateActionUpdate
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"distribute_alert_yes", @"Sasquatch", @"")
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                        [MSACDistribute notifyUpdateAction:MSACUpdateActionUpdate];
                                                      }]];

    // Add a "No"-Button and call the notifyUpdateAction-callback with MSUpdateActionPostpone
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"distribute_alert_no", @"Sasquatch", @"")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                        [MSACDistribute notifyUpdateAction:MSACUpdateActionPostpone];
                                                      }]];

    // Show the alert controller.
    [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
    return YES;
  }
  return NO;
}

#endif

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
    [manager requestLocation];
  }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
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
