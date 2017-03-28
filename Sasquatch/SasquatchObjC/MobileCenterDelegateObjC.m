#import "MobileCenterDelegateObjC.h"

@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;
@import MobileCenterDistribute;

/*
 * MobileCenterDelegate implementation in Objective C.
 */

@implementation MobileCenterDelegateObjC

- (BOOL) isMobileCenterEnabled{
  return [MSMobileCenter isEnabled];
}
- (void) setMobileCenterEnabled:(BOOL)isEnabled{
  return [MSMobileCenter setEnabled:isEnabled];
}
- (NSString *) installId{
  return [[MSMobileCenter installId] UUIDString];
}
- (BOOL) hasCrashedInLastSession{
  return [MSCrashes hasCrashedInLastSession];
}
- (BOOL) isAnalyticsEnabled{
  return [MSAnalytics isEnabled];
}
- (BOOL) isCrashesEnabled{
  return [MSCrashes isEnabled];
}
- (BOOL) isDistributeEnabled{
  return [MSDistribute isEnabled];
}
- (void) setAnalyticsEnabled:(BOOL)isEnabled{
  return [MSAnalytics setEnabled:isEnabled];
}
- (void) setCrashesEnabled:(BOOL)isEnabled{
  return [MSCrashes setEnabled:isEnabled];
}
- (void) setDistributeEnabled:(BOOL)isEnabled{
  return [MSDistribute setEnabled:isEnabled];
}
- (BOOL) isDebuggerAttached{
  return [MSMobileCenter isDebuggerAttached];
}
- (void) generateTestCrash{
  return [MSCrashes generateTestCrash];
}
- (void) trackEvent:(NSString *) eventName{
  [MSAnalytics trackEvent:eventName];
}
- (void) trackEvent:(NSString *)eventName withProperties:(NSDictionary<NSString *, NSString *> *)properties{
  [MSAnalytics trackEvent:eventName withProperties:properties];
}
- (void) trackPage:(NSString *) eventName{
  // TODO
  // Uncomment when trackPage is moved from internal to public module
  // [MSAnalytics trackPage:eventName];
}
- (void) trackPage:(NSString *)eventName withProperties:(NSDictionary<NSString *, NSString *> *)properties{
  // TODO
  // Uncomment when trackPage is moved from internal to public module
  // [MSAnalytics trackPage:eventName withProperties:properties];
}
- (NSString *) lastCrashReportIncidentIdentifier{
  return [[MSCrashes lastSessionCrashReport] incidentIdentifier];
}
- (NSString *) lastCrashReportReporterKey{
  return [[MSCrashes lastSessionCrashReport] reporterKey];
}
- (NSString *) lastCrashReportSignal{
  return [[MSCrashes lastSessionCrashReport] signal];
}
- (NSString *) lastCrashReportExceptionName{
  return [[MSCrashes lastSessionCrashReport] exceptionName];
}
- (NSString *) lastCrashReportExceptionReason{
  return [[MSCrashes lastSessionCrashReport] exceptionReason];
}
- (NSString *) lastCrashReportAppStartTimeDescription{
  return [[[MSCrashes lastSessionCrashReport] appStartTime] description];
}
- (NSString *) lastCrashReportAppErrorTimeDescription{
  return [[[MSCrashes lastSessionCrashReport] appErrorTime] description];
}
- (NSUInteger) lastCrashReportAppProcessIdentifier{
  return [[MSCrashes lastSessionCrashReport] appProcessIdentifier];
}
- (BOOL) lastCrashReportIsAppKill{
  return [[MSCrashes lastSessionCrashReport] isAppKill];
}
- (NSString *) lastCrashReportDeviceModel{
  return [[[MSCrashes lastSessionCrashReport] device] model];
}
- (NSString *) lastCrashReportDeviceOemName{
  return [[[MSCrashes lastSessionCrashReport] device] oemName];
}
- (NSString *) lastCrashReportDeviceOsName{
  return [[[MSCrashes lastSessionCrashReport] device] osName];
}
- (NSString *) lastCrashReportDeviceOsVersion{
  return [[[MSCrashes lastSessionCrashReport] device] osVersion];
}
- (NSString *) lastCrashReportDeviceOsBuild{
  return [[[MSCrashes lastSessionCrashReport] device] osBuild];
}
- (NSString *) lastCrashReportDeviceLocale{
  return [[[MSCrashes lastSessionCrashReport] device] locale];
}
- (NSNumber *) lastCrashReportDeviceTimeZoneOffset{
  return [[[MSCrashes lastSessionCrashReport] device] timeZoneOffset];
}
- (NSString *) lastCrashReportDeviceScreenSize{
  return [[[MSCrashes lastSessionCrashReport] device] screenSize];
}
- (NSString *) lastCrashReportDeviceAppVersion{
  return [[[MSCrashes lastSessionCrashReport] device] appVersion];
}
- (NSString *) lastCrashReportDeviceAppBuild{
  return [[[MSCrashes lastSessionCrashReport] device] appBuild];
}
- (NSString *) lastCrashReportDeviceAppNamespace{
  return [[[MSCrashes lastSessionCrashReport] device] appNamespace];
}
- (NSString *) lastCrashReportDeviceCarrierName{
  return [[[MSCrashes lastSessionCrashReport] device] carrierName];
}
- (NSString *) lastCrashReportDeviceCarrierCountry{
  return [[[MSCrashes lastSessionCrashReport] device] carrierCountry];
}

@end
