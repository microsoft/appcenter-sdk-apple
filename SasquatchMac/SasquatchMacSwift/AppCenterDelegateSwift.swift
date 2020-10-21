// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

/**
 * AppCenterDelegate implementation in Swift.
 */
class AppCenterDelegateSwift : AppCenterDelegate {

  //MARK: AppCenter section.
  func isAppCenterEnabled() -> Bool {
    return AppCenter.enabled
  }
  func setAppCenterEnabled(_ isEnabled: Bool) {
    AppCenter.enabled = isEnabled
  }
  func setCountryCode(_ countryCode: String?) {
    AppCenter.countryCode = countryCode
  }
  func setCustomProperties(_ customProperties: CustomProperties){
    AppCenter.setCustomProperties(customProperties)
  }
  func installId() -> String {
    return AppCenter.installId.uuidString
  }
  func appSecret() -> String {
    return kMSSwiftAppSecret
  }
  func isDebuggerAttached() -> Bool {
    return AppCenter.isDebuggerAttached
  }
  func startAnalyticsFromLibrary() {
    AppCenter.startFromLibrary(services: [Analytics.self])
  }
  func setUserId(_ userId: String?) {
    AppCenter.userId = userId;
  }
  func setLogUrl(_ logUrl: String?) {
    AppCenter.logUrl = logUrl;
  }

  //MARK: Modules section.
  func isAnalyticsEnabled() -> Bool {
    return Analytics.enabled
  }
  func isCrashesEnabled() -> Bool {
    return Crashes.enabled
  }
  func setAnalyticsEnabled(_ isEnabled: Bool) {
    Analytics.enabled = isEnabled
  }
  func setCrashesEnabled(_ isEnabled: Bool) {
    Crashes.enabled = isEnabled
  }

  //MARK: Analytics section.
  func trackEvent(_ eventName: String) {
    Analytics.trackEvent(eventName)
  }
  func trackEvent(_ eventName: String, withProperties properties: Dictionary<String, String>) {
    Analytics.trackEvent(eventName, withProperties: properties)
  }
  func trackEvent(_ eventName: String, withProperties properties: Dictionary<String, String>, flags: Flags) {
    Analytics.trackEvent(eventName, withProperties: properties, flags:flags)
  }
  func trackEvent(_ eventName: String, withTypedProperties properties: EventProperties) {
    Analytics.trackEvent(eventName, withProperties: properties)
  }
  func trackEvent(_ eventName: String, withTypedProperties properties: EventProperties?, flags: Flags) {
    Analytics.trackEvent(eventName, withProperties: properties, flags: flags)
  }
  func resume() {
    Analytics.resume()
  }
  func pause() {
    Analytics.pause()
  }
  #warning("TODO: Uncomment when trackPage is moved from internal to public")
  func trackPage(_ pageName: String) {
    // Analytics.trackPage(pageName)
  }
  #warning("TODO: Uncomment when trackPage is moved from internal to public")
  func trackPage(_ pageName: String, withProperties properties: Dictionary<String, String>) {
    // Analytics.trackPage(pageName, withProperties: properties)
  }

  //MARK: Crashes section.
  func hasCrashedInLastSession() -> Bool {
    return Crashes.hasCrashedInLastSession
  }
  func generateTestCrash() {
    Crashes.generateTestCrash()
  }

  //MARK: Last crash report section.
  func lastCrashReportIncidentIdentifier() -> String? {
    return Crashes.lastSessionCrashReport?.incidentIdentifier
  }
  func lastCrashReportReporterKey() -> String? {
    return Crashes.lastSessionCrashReport?.reporterKey
  }
  func lastCrashReportSignal() -> String? {
    return Crashes.lastSessionCrashReport?.signal
  }
  func lastCrashReportExceptionName() -> String? {
    return Crashes.lastSessionCrashReport?.exceptionName
  }
  func lastCrashReportExceptionReason() -> String? {
    return Crashes.lastSessionCrashReport?.exceptionReason
  }
  func lastCrashReportAppStartTimeDescription() -> String? {
    return Crashes.lastSessionCrashReport?.appStartTime.description
  }
  func lastCrashReportAppErrorTimeDescription() -> String? {
    return Crashes.lastSessionCrashReport?.appErrorTime.description
  }
  func lastCrashReportAppProcessIdentifier() -> UInt {
    return (Crashes.lastSessionCrashReport?.appProcessIdentifier)!
  }
  func lastCrashReportIsAppKill() -> Bool {
    return (Crashes.lastSessionCrashReport?.isAppKill)!
  }
  func lastCrashReportDeviceModel() -> String? {
    return Crashes.lastSessionCrashReport?.device.model
  }
  func lastCrashReportDeviceOemName() -> String? {
    return Crashes.lastSessionCrashReport?.device.oemName
  }
  func lastCrashReportDeviceOsName() -> String? {
    return Crashes.lastSessionCrashReport?.device.osName
  }
  func lastCrashReportDeviceOsVersion() -> String? {
    return Crashes.lastSessionCrashReport?.device.osVersion
  }
  func lastCrashReportDeviceOsBuild() -> String? {
    return Crashes.lastSessionCrashReport?.device.osBuild
  }
  func lastCrashReportDeviceLocale() -> String? {
    return Crashes.lastSessionCrashReport?.device.locale
  }
  func lastCrashReportDeviceTimeZoneOffset() -> NSNumber? {
    return Crashes.lastSessionCrashReport?.device.timeZoneOffset
  }
  func lastCrashReportDeviceScreenSize() -> String? {
    return Crashes.lastSessionCrashReport?.device.screenSize
  }
  func lastCrashReportDeviceAppVersion() -> String? {
    return Crashes.lastSessionCrashReport?.device.appVersion
  }
  func lastCrashReportDeviceAppBuild() -> String? {
    return Crashes.lastSessionCrashReport?.device.appBuild
  }
  func lastCrashReportDeviceCarrierName() -> String? {
    return Crashes.lastSessionCrashReport?.device.carrierName
  }
  func lastCrashReportDeviceCarrierCountry() -> String? {
    return Crashes.lastSessionCrashReport?.device.carrierCountry
  }
  func lastCrashReportDeviceAppNamespace() -> String? {
    return Crashes.lastSessionCrashReport?.device.appNamespace
  }

  //MARK: MSEventFilter section.
  func isEventFilterEnabled() -> Bool{
    return MSEventFilter.enabled;
  }
  func setEventFilterEnabled(_ isEnabled: Bool){
    MSEventFilter.enabled = isEnabled;
  }
  func startEventFilterService() {
    AppCenter.startService(MSEventFilter.self)
  }
}
