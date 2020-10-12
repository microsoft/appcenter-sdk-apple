// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenterPush

/**
 * AppCenterDelegate implementation in Swift.
 */
class AppCenterDelegateSwift : AppCenterDelegate {

  //MARK: MSACAppCenter section.
  func isAppCenterEnabled() -> Bool {
    return MSACAppCenter.isEnabled()
  }
  func setAppCenterEnabled(_ isEnabled: Bool) {
    MSACAppCenter.setEnabled(isEnabled)
  }
  func setCountryCode(_ countryCode: String?) {
    MSACAppCenter.setCountryCode(countryCode)
  }
  func setCustomProperties(_ customProperties: MSACCustomProperties){
    MSACAppCenter.setCustomProperties(customProperties)
  }
  func installId() -> String {
    return MSACAppCenter.installId().uuidString
  }
  func appSecret() -> String {
    return kMSSwiftAppSecret
  }
  func isDebuggerAttached() -> Bool {
    return MSACAppCenter.isDebuggerAttached()
  }
  func startAnalyticsFromLibrary() {
    MSACAppCenter.startFromLibrary(withServices: [MSACAnalytics.self])
  }
  func setUserId(_ userId: String?) {
    MSACAppCenter.setUserId(userId);
  }
  func setLogUrl(_ logUrl: String?) {
    MSACAppCenter.setLogUrl(logUrl);
  }

  //MARK: Modules section.
  func isAnalyticsEnabled() -> Bool {
    return MSACAnalytics.isEnabled()
  }
  func isCrashesEnabled() -> Bool {
    return MSACCrashes.isEnabled()
  }
  func isPushEnabled() -> Bool {
    return MSPush.isEnabled()
  }
  func setAnalyticsEnabled(_ isEnabled: Bool) {
    MSACAnalytics.setEnabled(isEnabled)
  }
  func setCrashesEnabled(_ isEnabled: Bool) {
    MSACCrashes.setEnabled(isEnabled)
  }
  func setPushEnabled(_ isEnabled: Bool) {
    MSPush.setEnabled(isEnabled)
  }

  //MARK: MSACAnalytics section.
  func trackEvent(_ eventName: String) {
    MSACAnalytics.trackEvent(eventName)
  }
  func trackEvent(_ eventName: String, withProperties properties: Dictionary<String, String>) {
    MSACAnalytics.trackEvent(eventName, withProperties: properties)
  }
  func trackEvent(_ eventName: String, withProperties properties: Dictionary<String, String>, flags: MSACFlags) {
    MSACAnalytics.trackEvent(eventName, withProperties: properties, flags:flags)
  }
  func trackEvent(_ eventName: String, withTypedProperties properties: MSACEventProperties) {
    MSACAnalytics.trackEvent(eventName, withProperties: properties)
  }
  func trackEvent(_ eventName: String, withTypedProperties properties: MSACEventProperties?, flags: MSACFlags) {
    MSACAnalytics.trackEvent(eventName, withProperties: properties, flags: flags)
  }
  func resume() {
    MSACAnalytics.resume()
  }
  func pause() {
    MSACAnalytics.pause()
  }
  #warning("TODO: Uncomment when trackPage is moved from internal to public")
  func trackPage(_ pageName: String) {
    // MSACAnalytics.trackPage(pageName)
  }
  #warning("TODO: Uncomment when trackPage is moved from internal to public")
  func trackPage(_ pageName: String, withProperties properties: Dictionary<String, String>) {
    // MSACAnalytics.trackPage(pageName, withProperties: properties)
  }

  //MARK: MSACCrashes section.
  func hasCrashedInLastSession() -> Bool {
    return MSACCrashes.hasCrashedInLastSession()
  }
  func generateTestCrash() {
    MSACCrashes.generateTestCrash()
  }

  //MARK: Last crash report section.
  func lastCrashReportIncidentIdentifier() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.incidentIdentifier
  }
  func lastCrashReportReporterKey() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.reporterKey
  }
  func lastCrashReportSignal() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.signal
  }
  func lastCrashReportExceptionName() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.exceptionName
  }
  func lastCrashReportExceptionReason() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.exceptionReason
  }
  func lastCrashReportAppStartTimeDescription() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.appStartTime.description
  }
  func lastCrashReportAppErrorTimeDescription() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.appErrorTime.description
  }
  func lastCrashReportAppProcessIdentifier() -> UInt {
    return (MSACCrashes.lastSessionCrashReport()?.appProcessIdentifier)!
  }
  func lastCrashReportIsAppKill() -> Bool {
    return (MSACCrashes.lastSessionCrashReport()?.isAppKill())!
  }
  func lastCrashReportDeviceModel() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.device.model
  }
  func lastCrashReportDeviceOemName() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.device.oemName
  }
  func lastCrashReportDeviceOsName() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.device.osName
  }
  func lastCrashReportDeviceOsVersion() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.device.osVersion
  }
  func lastCrashReportDeviceOsBuild() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.device.osBuild
  }
  func lastCrashReportDeviceLocale() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.device.locale
  }
  func lastCrashReportDeviceTimeZoneOffset() -> NSNumber? {
    return MSACCrashes.lastSessionCrashReport()?.device.timeZoneOffset
  }
  func lastCrashReportDeviceScreenSize() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.device.screenSize
  }
  func lastCrashReportDeviceAppVersion() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.device.appVersion
  }
  func lastCrashReportDeviceAppBuild() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.device.appBuild
  }
  func lastCrashReportDeviceCarrierName() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.device.carrierName
  }
  func lastCrashReportDeviceCarrierCountry() -> String? {
    return MSACCrashes.lastSessionCrashReport()?.device.carrierCountry
  }
  func lastCrashReportDeviceAppNamespace() -> String? {
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
