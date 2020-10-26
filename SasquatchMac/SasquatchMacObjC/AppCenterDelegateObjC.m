// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenterDelegateObjC.h"
#import "MSEventFilter.h"
#import "Constants.h"

@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;

/**
 * AppCenterDelegate implementation in Objective C.
 */
@implementation AppCenterDelegateObjC

#pragma mark - MSACAppCenter section.

- (BOOL)isAppCenterEnabled {
  return [MSACAppCenter isEnabled];
}

- (void)setAppCenterEnabled:(BOOL)isEnabled {
  return [MSACAppCenter setEnabled:isEnabled];
}

- (void)setCountryCode:(NSString *)countryCode {
  return [MSACAppCenter setCountryCode:countryCode];
}

- (void)setCustomProperties:(MSACCustomProperties *)customProperties {
  [MSACAppCenter setCustomProperties:customProperties];
}

- (void)startAnalyticsFromLibrary {
  [MSACAppCenter startFromLibraryWithServices:@ [[MSACAnalytics class]]];
}

- (NSString *)installId {
  return [[MSACAppCenter installId] UUIDString];
}

- (NSString *)appSecret {
  return kMSObjcAppSecret;
}

- (BOOL)isDebuggerAttached {
  return [MSACAppCenter isDebuggerAttached];
}

- (void)setUserId:(NSString *)userId {
  [MSACAppCenter setUserId:userId];
}

- (void)setLogUrl:(NSString *)logUrl {
  [MSACAppCenter setLogUrl:logUrl];
}

#pragma mark - Modules section.

- (BOOL)isAnalyticsEnabled {
  return [MSACAnalytics isEnabled];
}

- (BOOL)isCrashesEnabled {
  return [MSACCrashes isEnabled];
}

- (void)setAnalyticsEnabled:(BOOL)isEnabled {
  return [MSACAnalytics setEnabled:isEnabled];
}

- (void)setCrashesEnabled:(BOOL)isEnabled {
  return [MSACCrashes setEnabled:isEnabled];
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

  // TODO: Uncomment when trackPage is moved from internal to public module
  // [MSACAnalytics trackPage:pageName];
}

- (void)trackPage:(NSString *)pageName withProperties:(NSDictionary<NSString *, NSString *> *)properties {

  // TODO: Uncomment when trackPage is moved from internal to public module
  // [MSACAnalytics trackPage:pageName withProperties:properties];
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

- (void)generateTestCrash {
  return [MSACCrashes generateTestCrash];
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

#pragma mark - MSEventFilter section.

- (BOOL)isEventFilterEnabled {
  return [MSEventFilter isEnabled];
}

- (void)setEventFilterEnabled:(BOOL)isEnabled {
  [MSEventFilter setEnabled:isEnabled];
}

- (void)startEventFilterService {
  [MSACAppCenter startService:[MSEventFilter class]];
}

@end
