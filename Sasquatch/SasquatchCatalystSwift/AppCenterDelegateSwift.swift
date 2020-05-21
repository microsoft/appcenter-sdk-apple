// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

/**
 * AppCenterDelegate implementation in Swift.
 */
class AppCenterDelegateSwift: AppCenterDelegate {

  // MSAppCenter section.
  func isAppCenterEnabled() -> Bool {
    return MSAppCenter.isEnabled()
  }

  func setAppCenterEnabled(_ isEnabled: Bool) {
    MSAppCenter.setEnabled(isEnabled)
  }

  func setCustomProperties(_ customProperties: MSCustomProperties) {
    MSAppCenter.setCustomProperties(customProperties)
  }

  func installId() -> String {
    return MSAppCenter.installId().uuidString
  }

  func appSecret() -> String {
    return kMSSwiftAppSecret
  }

  func setLogUrl(_ logUrl: String?) {
    MSAppCenter.setLogUrl(logUrl);
  }

  func sdkVersion() -> String {
    return MSAppCenter.sdkVersion()
  }

  func isDebuggerAttached() -> Bool {
    return MSAppCenter.isDebuggerAttached()
  }

  func startAnalyticsFromLibrary() {
    MSAppCenter.startFromLibrary(withServices: [MSAnalytics.self])
  }

  func setUserId(_ userId: String?) {
    MSAppCenter.setUserId(userId);
  }

  func setCountryCode(_ countryCode: String?) {
    MSAppCenter.setCountryCode(countryCode);
  }

  // Modules section.
  func isAnalyticsEnabled() -> Bool {
    return MSAnalytics.isEnabled()
  }

  func isCrashesEnabled() -> Bool {
    return MSCrashes.isEnabled()
  }

  func setAnalyticsEnabled(_ isEnabled: Bool) {
    MSAnalytics.setEnabled(isEnabled)
  }

  func setCrashesEnabled(_ isEnabled: Bool) {
    MSCrashes.setEnabled(isEnabled)
  }

  // MSAnalytics section.
  func trackEvent(_ eventName: String) {
    MSAnalytics.trackEvent(eventName)
  }

  func trackEvent(_ eventName: String, withProperties properties: Dictionary<String, String>) {
    MSAnalytics.trackEvent(eventName, withProperties: properties)
  }

  func trackEvent(_ eventName: String, withProperties properties: Dictionary<String, String>, flags: MSFlags) {
    MSAnalytics.trackEvent(eventName, withProperties: properties, flags:flags)
  }

  func trackEvent(_ eventName: String, withTypedProperties properties: MSEventProperties) {
    MSAnalytics.trackEvent(eventName, withProperties: properties)
  }

  func trackEvent(_ eventName: String, withTypedProperties properties: MSEventProperties?, flags: MSFlags) {
    MSAnalytics.trackEvent(eventName, withProperties: properties, flags: flags)
  }

  #warning("TODO: Uncomment when trackPage is moved from internal to public")
  func trackPage(_ pageName: String) {
    // MSAnalytics.trackPage(pageName)
  }

  #warning("TODO: Uncomment when trackPage is moved from internal to public")
  func trackPage(_ pageName: String, withProperties properties: Dictionary<String, String>) {
    // MSAnalytics.trackPage(pageName, withProperties: properties)
  }

  func resume() {
    MSAnalytics.resume()
  }

  func pause() {
    MSAnalytics.pause()
  }

  // MSCrashes section.
  func hasCrashedInLastSession() -> Bool {
    return MSCrashes.hasCrashedInLastSession()
  }

  func hasReceivedMemoryWarningInLastSession() -> Bool {
    return MSCrashes.hasReceivedMemoryWarningInLastSession()
  }

  func generateTestCrash() {
    MSCrashes.generateTestCrash()
  }

  // Last crash report section.
  func lastCrashReportIncidentIdentifier() -> String? {
    return MSCrashes.lastSessionCrashReport()?.incidentIdentifier
  }

  func lastCrashReportReporterKey() -> String? {
    return MSCrashes.lastSessionCrashReport()?.reporterKey
  }

  func lastCrashReportSignal() -> String? {
    return MSCrashes.lastSessionCrashReport()?.signal
  }

  func lastCrashReportExceptionName() -> String? {
    return MSCrashes.lastSessionCrashReport()?.exceptionName
  }

  func lastCrashReportExceptionReason() -> String? {
    return MSCrashes.lastSessionCrashReport()?.exceptionReason
  }

  func lastCrashReportAppStartTimeDescription() -> String? {
    return MSCrashes.lastSessionCrashReport()?.appStartTime.description
  }

  func lastCrashReportAppErrorTimeDescription() -> String? {
    return MSCrashes.lastSessionCrashReport()?.appErrorTime.description
  }

  func lastCrashReportAppProcessIdentifier() -> UInt {
    return (MSCrashes.lastSessionCrashReport()?.appProcessIdentifier)!
  }

  func lastCrashReportIsAppKill() -> Bool {
    return (MSCrashes.lastSessionCrashReport()?.isAppKill())!
  }

  func lastCrashReportDeviceModel() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.model
  }

  func lastCrashReportDeviceOemName() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.oemName
  }

  func lastCrashReportDeviceOsName() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.osName
  }

  func lastCrashReportDeviceOsVersion() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.osVersion
  }

  func lastCrashReportDeviceOsBuild() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.osBuild
  }

  func lastCrashReportDeviceLocale() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.locale
  }

  func lastCrashReportDeviceTimeZoneOffset() -> NSNumber? {
    return MSCrashes.lastSessionCrashReport()?.device.timeZoneOffset
  }

  func lastCrashReportDeviceScreenSize() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.screenSize
  }

  func lastCrashReportDeviceAppVersion() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.appVersion
  }

  func lastCrashReportDeviceAppBuild() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.appBuild
  }

  func lastCrashReportDeviceCarrierName() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.carrierName
  }

  func lastCrashReportDeviceCarrierCountry() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.carrierCountry
  }

  func lastCrashReportDeviceAppNamespace() -> String? {
    return MSCrashes.lastSessionCrashReport()?.device.appNamespace
  }

  // MSDistribute section.
  func showConfirmationAlert() {}
  func checkForUpdate() {}
  func showDistributeDisabledAlert() {}
  func showCustomConfirmationAlert() {}

  func isDistributeEnabled() -> Bool {
    return false
  }

  func isPushEnabled() -> Bool {
    return false
  }

  func setDistributeEnabled(_ isEnabled: Bool) {
  }

  func setPushEnabled(_ isEnabled: Bool){
  }
}
