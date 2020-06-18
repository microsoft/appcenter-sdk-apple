// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#if GCC_PREPROCESSOR_MACRO_PUPPET
#import "AppCenter.h"
#import "AppCenterAnalytics.h"
#import "AppCenterCrashes.h"
#if !TARGET_OS_MACCATALYST
#import "AppCenterDistribute.h"
#import "AppCenterPush.h"
#endif
// Internal
#import "MSAnalyticsInternal.h"
#import "MSAppCenterInternal.h"

#elif GCC_PREPROCESSOR_MACRO_SASQUATCH_OBJC
#import <AppCenter/AppCenter.h>
#import <AppCenterAnalytics/AppCenterAnalytics.h>
#import <AppCenterCrashes/AppCenterCrashes.h>
#import <AppCenterDistribute/AppCenterDistribute.h>
#import <AppCenterPush/AppCenterPush.h>
#else
@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;
@import AppCenterDistribute;
@import AppCenterPush;
#endif

#import "AppCenterDelegateObjC.h"
#import "Constants.h"

/**
 * AppCenterDelegate implementation in Objective C.
 */
@implementation AppCenterDelegateObjC

#pragma mark - MSAppCenter section.

- (BOOL)isAppCenterEnabled {
  return [MSAppCenter isEnabled];
}

- (void)setAppCenterEnabled:(BOOL)isEnabled {
  [MSAppCenter setEnabled:isEnabled];
}

- (NSString *)installId {
  return [[MSAppCenter installId] UUIDString];
}

- (NSString *)appSecret {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  return [[MSAppCenter sharedInstance] appSecret];
#else
  return kMSObjcAppSecret;
#endif
}

- (void)setLogUrl:(NSString *)logUrl {
  [MSAppCenter setLogUrl:logUrl];
}

- (NSString *)sdkVersion {
  return [MSAppCenter sdkVersion];
}

- (BOOL)isDebuggerAttached {
  return [MSAppCenter isDebuggerAttached];
}

- (void)setCustomProperties:(MSCustomProperties *)customProperties {
  [MSAppCenter setCustomProperties:customProperties];
}

- (void)startAnalyticsFromLibrary {
  [MSAppCenter startFromLibraryWithServices:@ [[MSAnalytics class]]];
}

- (void)setUserId:(NSString *)userId {
  [MSAppCenter setUserId:userId];
}

- (void)setCountryCode:(NSString *)countryCode {
  [MSAppCenter setCountryCode:countryCode];
}

#pragma mark - Modules section.

- (BOOL)isAnalyticsEnabled {
  return [MSAnalytics isEnabled];
}

- (BOOL)isCrashesEnabled {
  return [MSCrashes isEnabled];
}

- (BOOL)isDistributeEnabled {
#if !TARGET_OS_MACCATALYST
  return [MSDistribute isEnabled];
#else
  return NO;
#endif
}

- (BOOL)isPushEnabled {
#if !TARGET_OS_MACCATALYST
  return [MSPush isEnabled];
#else
  return NO;
#endif
}

- (void)setAnalyticsEnabled:(BOOL)isEnabled {
  [MSAnalytics setEnabled:isEnabled];
}

- (void)setCrashesEnabled:(BOOL)isEnabled {
  [MSCrashes setEnabled:isEnabled];
}

- (void)setDistributeEnabled:(BOOL)isEnabled {
#if !TARGET_OS_MACCATALYST
  [MSDistribute setEnabled:isEnabled];
#endif
}

- (void)setPushEnabled:(BOOL)isEnabled {
#if !TARGET_OS_MACCATALYST
  [MSPush setEnabled:isEnabled];
#endif
}

#pragma mark - MSAnalytics section.

- (void)trackEvent:(NSString *)eventName {
  [MSAnalytics trackEvent:eventName];
}

- (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary<NSString *, NSString *> *)properties {
  [MSAnalytics trackEvent:eventName withProperties:properties];
}

- (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary<NSString *, NSString *> *)properties flags:(MSFlags)flags {
  [MSAnalytics trackEvent:eventName withProperties:properties flags:flags];
}

- (void)trackEvent:(NSString *)eventName withTypedProperties:(MSEventProperties *)properties {
  [MSAnalytics trackEvent:eventName withTypedProperties:properties];
}

- (void)trackEvent:(NSString *)eventName withTypedProperties:(MSEventProperties *)properties flags:(MSFlags)flags {
  [MSAnalytics trackEvent:eventName withTypedProperties:properties flags:flags];
}

- (void)trackPage:(NSString *)pageName {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  [MSAnalytics trackPage:pageName];
#endif
}

- (void)trackPage:(NSString *)pageName withProperties:(NSDictionary<NSString *, NSString *> *)properties {
#if GCC_PREPROCESSOR_MACRO_PUPPET
  [MSAnalytics trackPage:pageName withProperties:properties];
#endif
}

- (void)resume {
  [MSAnalytics resume];
}

- (void)pause {
  [MSAnalytics pause];
}

#pragma mark - MSCrashes section.

- (BOOL)hasCrashedInLastSession {
  return [MSCrashes hasCrashedInLastSession];
}

- (BOOL)hasReceivedMemoryWarningInLastSession {
  return [MSCrashes hasReceivedMemoryWarningInLastSession];
}

- (void)generateTestCrash {
  return [MSCrashes generateTestCrash];
}

#pragma mark - MSDistribute section.
- (void)showConfirmationAlert {
#if !TARGET_OS_MACCATALYST
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  MSReleaseDetails *releaseDetails = [MSReleaseDetails new];
  releaseDetails.version = @"10";
  releaseDetails.shortVersion = @"1.0";
  if ([MSDistribute respondsToSelector:@selector(sharedInstance)]) {
    id distributeInstance = [MSDistribute performSelector:@selector(sharedInstance)];
    if ([distributeInstance respondsToSelector:@selector(showConfirmationAlert:)]) {
      [distributeInstance performSelector:@selector(showConfirmationAlert:) withObject:releaseDetails];
    }
  }
#pragma clang diagnostic pop
#endif
}

- (void)showDistributeDisabledAlert {
#if !TARGET_OS_MACCATALYST
  if ([MSDistribute respondsToSelector:@selector(sharedInstance)]) {
    id distributeInstance = [MSDistribute performSelector:@selector(sharedInstance)];
    if ([distributeInstance respondsToSelector:@selector(showDistributeDisabledAlert)]) {
      [distributeInstance performSelector:@selector(showDistributeDisabledAlert)];
    }
  }
#endif
}

- (void)showCustomConfirmationAlert {
#if !TARGET_OS_MACCATALYST
  MSReleaseDetails *releaseDetails = [MSReleaseDetails new];
  releaseDetails.version = @"10";
  releaseDetails.shortVersion = @"1.0";
  if ([MSDistribute respondsToSelector:@selector(sharedInstance)]) {
    id distributeInstance = [MSDistribute performSelector:@selector(sharedInstance)];
    [[distributeInstance delegate] distribute:distributeInstance releaseAvailableWithDetails:releaseDetails];
  }
#endif
}

- (void)checkForUpdate {
#if !TARGET_OS_MACCATALYST
  [MSDistribute checkForUpdate];
#endif
}

#pragma mark - Last crash report section.

- (NSString *)lastCrashReportIncidentIdentifier {
  return [[MSCrashes lastSessionCrashReport] incidentIdentifier];
}

- (NSString *)lastCrashReportReporterKey {
  return [[MSCrashes lastSessionCrashReport] reporterKey];
}

- (NSString *)lastCrashReportSignal {
  return [[MSCrashes lastSessionCrashReport] signal];
}

- (NSString *)lastCrashReportExceptionName {
  return [[MSCrashes lastSessionCrashReport] exceptionName];
}

- (NSString *)lastCrashReportExceptionReason {
  return [[MSCrashes lastSessionCrashReport] exceptionReason];
}

- (NSString *)lastCrashReportAppStartTimeDescription {
  return [[[MSCrashes lastSessionCrashReport] appStartTime] description];
}

- (NSString *)lastCrashReportAppErrorTimeDescription {
  return [[[MSCrashes lastSessionCrashReport] appErrorTime] description];
}

- (NSUInteger)lastCrashReportAppProcessIdentifier {
  return [[MSCrashes lastSessionCrashReport] appProcessIdentifier];
}

- (BOOL)lastCrashReportIsAppKill {
  return [[MSCrashes lastSessionCrashReport] isAppKill];
}

- (NSString *)lastCrashReportDeviceModel {
  return [[[MSCrashes lastSessionCrashReport] device] model];
}

- (NSString *)lastCrashReportDeviceOemName {
  return [[[MSCrashes lastSessionCrashReport] device] oemName];
}

- (NSString *)lastCrashReportDeviceOsName {
  return [[[MSCrashes lastSessionCrashReport] device] osName];
}

- (NSString *)lastCrashReportDeviceOsVersion {
  return [[[MSCrashes lastSessionCrashReport] device] osVersion];
}

- (NSString *)lastCrashReportDeviceOsBuild {
  return [[[MSCrashes lastSessionCrashReport] device] osBuild];
}

- (NSString *)lastCrashReportDeviceLocale {
  return [[[MSCrashes lastSessionCrashReport] device] locale];
}

- (NSNumber *)lastCrashReportDeviceTimeZoneOffset {
  return [[[MSCrashes lastSessionCrashReport] device] timeZoneOffset];
}

- (NSString *)lastCrashReportDeviceScreenSize {
  return [[[MSCrashes lastSessionCrashReport] device] screenSize];
}

- (NSString *)lastCrashReportDeviceAppVersion {
  return [[[MSCrashes lastSessionCrashReport] device] appVersion];
}

- (NSString *)lastCrashReportDeviceAppBuild {
  return [[[MSCrashes lastSessionCrashReport] device] appBuild];
}

- (NSString *)lastCrashReportDeviceAppNamespace {
  return [[[MSCrashes lastSessionCrashReport] device] appNamespace];
}

- (NSString *)lastCrashReportDeviceCarrierName {
  return [[[MSCrashes lastSessionCrashReport] device] carrierName];
}

- (NSString *)lastCrashReportDeviceCarrierCountry {
  return [[[MSCrashes lastSessionCrashReport] device] carrierCountry];
}

@end
