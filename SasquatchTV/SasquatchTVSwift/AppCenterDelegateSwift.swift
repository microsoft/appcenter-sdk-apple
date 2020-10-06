// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import AppCenter;
import AppCenterAnalytics;
import AppCenterCrashes;

/**
 * AppCenterDelegate implementation in Swift.
 */
class AppCenterDelegateSwift : AppCenterDelegate {

  // MARK: MSACAppCenter section.
  func isAppCenterEnabled()->Bool { return MSACAppCenter.isEnabled(); }
  func setAppCenterEnabled(_ isEnabled : Bool) { MSACAppCenter.setEnabled(isEnabled); }
  func installId()->String { return MSACAppCenter.installId().uuidString; }
  #warning("TODO: Uncomment when appSecret is moved from internal to public.")
  func appSecret()->String {
    // return MSACAppCenter.sharedInstance().appSecret()
    return "Internal";
  }
  #warning("TODO: Uncomment when appSecret is moved from internal to public.")
  func logUrl()->String {
    // return MSACAppCenter.sharedInstance().logUrl()
    return "Internal";
  }
  func isDebuggerAttached()->Bool { return MSACAppCenter.isDebuggerAttached(); }

  // MARK: MSACAnalytics section.
  func isAnalyticsEnabled()->Bool { return MSACAnalytics.isEnabled(); }

  func setAnalyticsEnabled(_ isEnabled : Bool) { MSACAnalytics.setEnabled(isEnabled); }

  func trackEvent(_ eventName : String) { MSACAnalytics.trackEvent(eventName); }

  func trackEvent(_ eventName : String, withProperties properties : Dictionary<String, String>) {
    MSACAnalytics.trackEvent(eventName, withProperties : properties);
  }

  #warning("TODO: Uncomment when trackPage is moved from internal to public.")
  func trackPage(_ pageName : String) {
    // MSACAnalytics.trackPage(pageName);
  }

  #warning("TODO: Uncomment when trackPage is moved from internal to public.")
  func trackPage(_ pageName : String, withProperties properties : Dictionary<String, String>) {
    // MSACAnalytics.trackPage(pageName, withProperties: properties);
  }

  // MARK: MSACCrashes section.

  func isCrashesEnabled() -> Bool{
    return MSACCrashes.isEnabled()
  }

  func setCrashesEnabled(_ isEnabled: Bool){
    MSACCrashes.setEnabled(isEnabled)
  }

  func hasCrashedInLastSession() -> Bool{
    return MSACCrashes.hasCrashedInLastSession()
  }

  func generateTestCrash() {
    MSACCrashes.generateTestCrash()
  }

  //MARK: Last crash report section.
  func lastCrashReportIncidentIdentifier() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.incidentIdentifier
  }
  func lastCrashReportReporterKey() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.reporterKey
  }
  func lastCrashReportSignal() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.signal
  }
  func lastCrashReportExceptionName() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.exceptionName
  }
  func lastCrashReportExceptionReason() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.exceptionReason
  }
  func lastCrashReportAppStartTimeDescription() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.appStartTime.description
  }
  func lastCrashReportAppErrorTimeDescription() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.appErrorTime.description
  }
  func lastCrashReportAppProcessIdentifier() -> UInt{
    return (MSACCrashes.lastSessionCrashReport()?.appProcessIdentifier)!
  }
  func lastCrashReportIsAppKill() -> Bool{
    return (MSACCrashes.lastSessionCrashReport()?.isAppKill())!
  }
  func lastCrashReportDeviceModel() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.model
  }
  func lastCrashReportDeviceOemName() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.oemName
  }
  func lastCrashReportDeviceOsName() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.osName
  }
  func lastCrashReportDeviceOsVersion() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.osVersion
  }
  func lastCrashReportDeviceOsBuild() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.osBuild
  }
  func lastCrashReportDeviceLocale() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.locale
  }
  func lastCrashReportDeviceTimeZoneOffset() -> NSNumber?{
    return MSACCrashes.lastSessionCrashReport()?.device.timeZoneOffset
  }
  func lastCrashReportDeviceScreenSize() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.screenSize
  }
  func lastCrashReportDeviceAppVersion() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.appVersion
  }
  func lastCrashReportDeviceAppBuild() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.appBuild
  }
  func lastCrashReportDeviceCarrierName() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.carrierName
  }
  func lastCrashReportDeviceCarrierCountry() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.carrierCountry
  }
  func lastCrashReportDeviceAppNamespace() -> String?{
    return MSACCrashes.lastSessionCrashReport()?.device.appNamespace
  }

  //MARK: MSEventFilter section.
  func isEventFilterEnabled() -> Bool{
    return MSEventFilter.isEnabled();
  }
  func setEventFilterEnabled(_ isEnabled: Bool){
    MSEventFilter.setEnabled(isEnabled);
  }
  func startEventFilterService() {
    MSACAppCenter.startService(MSEventFilter.self)
  }
}
