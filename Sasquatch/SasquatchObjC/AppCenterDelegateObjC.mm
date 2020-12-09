// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#if GCC_PREPROCESSOR_MACRO_PUPPET
#import "AppCenter.h"
#import "AppCenterAnalytics.h"
#import "AppCenterCrashes.h"
#if !TARGET_OS_MACCATALYST
#import "AppCenterDistribute.h"
#endif
// Internal
#import "MSACAnalyticsInternal.h"
#import "MSACAppCenterInternal.h"

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
#import "Constants.h"

/**
 * AppCenterDelegate implementation in Objective C.
 */
@implementation AppCenterDelegateObjC

#pragma mark - MSACAppCenter section.

- (BOOL)isAppCenterEnabled {
  return [MSACAppCenter isEnabled];
}

- (void)setAppCenterEnabled:(BOOL)isEnabled {
  [MSACAppCenter setEnabled:isEnabled];
}

- (NSString *)installId {
  return [[MSACAppCenter installId] UUIDString];
}

- (NSString *)appSecret {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  return [[MSACAppCenter sharedInstance] appSecret];
#else
  return kMSObjcAppSecret;
#endif
}

- (void)setLogUrl:(NSString *)logUrl {
  [MSACAppCenter setLogUrl:logUrl];
}

- (NSString *)sdkVersion {
  return [MSACAppCenter sdkVersion];
}

- (BOOL)isDebuggerAttached {
  return [MSACAppCenter isDebuggerAttached];
}

- (void)setCustomProperties:(MSACCustomProperties *)customProperties {
  [MSACAppCenter setCustomProperties:customProperties];
}

- (void)startAnalyticsFromLibrary {
  [MSACAppCenter startFromLibraryWithServices:@ [[MSACAnalytics class]]];
}

- (void)setUserId:(NSString *)userId {
  [MSACAppCenter setUserId:userId];
}

- (void)setCountryCode:(NSString *)countryCode {
  [MSACAppCenter setCountryCode:countryCode];
}

#pragma mark - Modules section.

- (BOOL)isAnalyticsEnabled {
  return [MSACAnalytics isEnabled];
}

- (BOOL)isCrashesEnabled {
  return [MSACCrashes isEnabled];
}

- (BOOL)isDistributeEnabled {
#if !TARGET_OS_MACCATALYST
  return [MSACDistribute isEnabled];
#else
  return NO;
#endif
}

- (void)setAnalyticsEnabled:(BOOL)isEnabled {
  [MSACAnalytics setEnabled:isEnabled];
}

- (void)setCrashesEnabled:(BOOL)isEnabled {
  [MSACCrashes setEnabled:isEnabled];
}

- (void)setDistributeEnabled:(BOOL)isEnabled {
#if !TARGET_OS_MACCATALYST
  [MSACDistribute setEnabled:isEnabled];
#endif
}

#pragma mark - MSACAnalytics section.

- (void)trackEvent:(NSString *)eventName {
  [MSACAnalytics trackEvent:eventName];
}

- (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary<NSString *, NSString *> *)properties {
  [MSACAnalytics trackEvent:eventName withProperties:properties];
}

- (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary<NSString *, NSString *> *)properties flags:(MSACFlags)flags {
  [MSACAnalytics trackEvent:eventName withProperties:properties flags:flags];
}

- (void)trackEvent:(NSString *)eventName withTypedProperties:(MSACEventProperties *)properties {
  [MSACAnalytics trackEvent:eventName withTypedProperties:properties];
}

- (void)trackEvent:(NSString *)eventName withTypedProperties:(MSACEventProperties *)properties flags:(MSACFlags)flags {
  [MSACAnalytics trackEvent:eventName withTypedProperties:properties flags:flags];
}

- (void)trackPage:(NSString *)pageName {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  [MSACAnalytics trackPage:pageName];
#endif
}

- (void)trackPage:(NSString *)pageName withProperties:(NSDictionary<NSString *, NSString *> *)properties {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  [MSACAnalytics trackPage:pageName withProperties:properties];
#endif
}

- (void)resume {
  [MSACAnalytics resume];
}

- (void)pause {
  [MSACAnalytics pause];
}

#pragma mark - MSACCrashes section.

- (BOOL)hasCrashedInLastSession {
  return [MSACCrashes hasCrashedInLastSession];
}

- (BOOL)hasReceivedMemoryWarningInLastSession {
  return [MSACCrashes hasReceivedMemoryWarningInLastSession];
}

- (void)generateTestCrash {
  return [MSACCrashes generateTestCrash];
}

#pragma mark - MSACDistribute section.
- (void)showConfirmationAlert {
#if !TARGET_OS_MACCATALYST
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  MSACReleaseDetails *releaseDetails = [MSACReleaseDetails new];
  releaseDetails.version = @"10";
  releaseDetails.shortVersion = @"1.0";
  if ([MSACDistribute respondsToSelector:@selector(sharedInstance)]) {
    id distributeInstance = [MSACDistribute performSelector:@selector(sharedInstance)];
    if ([distributeInstance respondsToSelector:@selector(showConfirmationAlert:)]) {
      [distributeInstance performSelector:@selector(showConfirmationAlert:) withObject:releaseDetails];
    }
  }
#pragma clang diagnostic pop
#endif
}

- (void)showDistributeDisabledAlert {
#if !TARGET_OS_MACCATALYST
  if ([MSACDistribute respondsToSelector:@selector(sharedInstance)]) {
    id distributeInstance = [MSACDistribute performSelector:@selector(sharedInstance)];
    if ([distributeInstance respondsToSelector:@selector(showDistributeDisabledAlert)]) {
      [distributeInstance performSelector:@selector(showDistributeDisabledAlert)];
    }
  }
#endif
}

- (void)showCustomConfirmationAlert {
#if !TARGET_OS_MACCATALYST
  MSACReleaseDetails *releaseDetails = [MSACReleaseDetails new];
  releaseDetails.version = @"10";
  releaseDetails.shortVersion = @"1.0";
  if ([MSACDistribute respondsToSelector:@selector(sharedInstance)]) {
    id distributeInstance = [MSACDistribute performSelector:@selector(sharedInstance)];
    [[distributeInstance delegate] distribute:distributeInstance releaseAvailableWithDetails:releaseDetails];
  }
#endif
}

- (void)checkForUpdate {
#if !TARGET_OS_MACCATALYST
  [MSACDistribute checkForUpdate];
#endif
}

- (void)closeApp {
#if !TARGET_OS_MACCATALYST
  if ([MSACDistribute respondsToSelector:@selector(sharedInstance)]) {
    id distributeInstance = [MSACDistribute performSelector:@selector(sharedInstance)];
    if ([distributeInstance respondsToSelector:@selector(closeApp)]) {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [distributeInstance performSelector:@selector(closeApp)];
      });
    }
  }
#endif
}

#pragma mark - Last crash report section.

- (NSString *)lastCrashReportIncidentIdentifier {
  return [[MSACCrashes lastSessionCrashReport] incidentIdentifier];
}

- (NSString *)lastCrashReportReporterKey {
  return [[MSACCrashes lastSessionCrashReport] reporterKey];
}

- (NSString *)lastCrashReportSignal {
  return [[MSACCrashes lastSessionCrashReport] signal];
}

- (NSString *)lastCrashReportExceptionName {
  return [[MSACCrashes lastSessionCrashReport] exceptionName];
}

- (NSString *)lastCrashReportExceptionReason {
  return [[MSACCrashes lastSessionCrashReport] exceptionReason];
}

- (NSString *)lastCrashReportAppStartTimeDescription {
  return [[[MSACCrashes lastSessionCrashReport] appStartTime] description];
}

- (NSString *)lastCrashReportAppErrorTimeDescription {
  return [[[MSACCrashes lastSessionCrashReport] appErrorTime] description];
}

- (NSUInteger)lastCrashReportAppProcessIdentifier {
  return [[MSACCrashes lastSessionCrashReport] appProcessIdentifier];
}

- (BOOL)lastCrashReportIsAppKill {
  return [[MSACCrashes lastSessionCrashReport] isAppKill];
}

- (NSString *)lastCrashReportDeviceModel {
  return [[[MSACCrashes lastSessionCrashReport] device] model];
}

- (NSString *)lastCrashReportDeviceOemName {
  return [[[MSACCrashes lastSessionCrashReport] device] oemName];
}

- (NSString *)lastCrashReportDeviceOsName {
  return [[[MSACCrashes lastSessionCrashReport] device] osName];
}

- (NSString *)lastCrashReportDeviceOsVersion {
  return [[[MSACCrashes lastSessionCrashReport] device] osVersion];
}

- (NSString *)lastCrashReportDeviceOsBuild {
  return [[[MSACCrashes lastSessionCrashReport] device] osBuild];
}

- (NSString *)lastCrashReportDeviceLocale {
  return [[[MSACCrashes lastSessionCrashReport] device] locale];
}

- (NSNumber *)lastCrashReportDeviceTimeZoneOffset {
  return [[[MSACCrashes lastSessionCrashReport] device] timeZoneOffset];
}

- (NSString *)lastCrashReportDeviceScreenSize {
  return [[[MSACCrashes lastSessionCrashReport] device] screenSize];
}

- (NSString *)lastCrashReportDeviceAppVersion {
  return [[[MSACCrashes lastSessionCrashReport] device] appVersion];
}

- (NSString *)lastCrashReportDeviceAppBuild {
  return [[[MSACCrashes lastSessionCrashReport] device] appBuild];
}

- (NSString *)lastCrashReportDeviceAppNamespace {
  return [[[MSACCrashes lastSessionCrashReport] device] appNamespace];
}

- (NSString *)lastCrashReportDeviceCarrierName {
  return [[[MSACCrashes lastSessionCrashReport] device] carrierName];
}

- (NSString *)lastCrashReportDeviceCarrierCountry {
  return [[[MSACCrashes lastSessionCrashReport] device] carrierCountry];
}

@end
