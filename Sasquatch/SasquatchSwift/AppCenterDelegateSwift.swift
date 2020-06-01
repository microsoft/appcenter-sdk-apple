// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
#if canImport(AppCenterDistribute)
import AppCenterDistribute

/**
 * Selectors for reflection.
 */
@objc protocol Selectors {
  func sharedInstance() -> MSDistribute
  func checkForUpdate()
  func showConfirmationAlert(_ releaseDetails: MSReleaseDetails)
  func showDistributeDisabledAlert()
  func delegate() -> MSDistributeDelegate
}
#endif
#if canImport(AppCenterPush)
import AppCenterPush
#endif

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
#if !targetEnvironment(macCatalyst)
    return kMSSwiftAppSecret
#else
    return kMSSwiftCatalystAppSecret
#endif
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

  func isDistributeEnabled() -> Bool {
#if canImport(AppCenterDistribute)
    return MSDistribute.isEnabled()
#else
    return false
#endif
  }

  func isPushEnabled() -> Bool {
#if canImport(AppCenterPush)
    return MSPush.isEnabled()
#else
    return false
#endif
  }

  func setAnalyticsEnabled(_ isEnabled: Bool) {
    MSAnalytics.setEnabled(isEnabled)
  }

  func setCrashesEnabled(_ isEnabled: Bool) {
    MSCrashes.setEnabled(isEnabled)
  }

  func setDistributeEnabled(_ isEnabled: Bool) {
#if canImport(AppCenterDistribute)
    MSDistribute.setEnabled(isEnabled)
#endif
  }

  func setPushEnabled(_ isEnabled: Bool) {
#if canImport(AppCenterPush)
    MSPush.setEnabled(isEnabled)
#endif
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

  // MSDistribute section.

  func checkForUpdate() {
#if canImport(AppCenterDistribute)
    MSDistribute.checkForUpdate()
#endif
  }

  func showConfirmationAlert() {
#if canImport(AppCenterDistribute)
    let sharedInstanceSelector = #selector(Selectors.sharedInstance)
    let confirmationAlertSelector = #selector(Selectors.showConfirmationAlert(_:))
    let releaseDetails = MSReleaseDetails();
    releaseDetails.version = "10";
    releaseDetails.shortVersion = "1.0";
    if (MSDistribute.responds(to: sharedInstanceSelector)) {
      let distributeInstance = MSDistribute.perform(sharedInstanceSelector).takeUnretainedValue()
      if (distributeInstance.responds(to: confirmationAlertSelector)) {
        _ = distributeInstance.perform(confirmationAlertSelector, with: releaseDetails)
      }
    }
#endif
  }

  func showDistributeDisabledAlert() {
#if canImport(AppCenterDistribute)
    let sharedInstanceSelector = #selector(Selectors.sharedInstance)
    let disabledAlertSelector = #selector(Selectors.showDistributeDisabledAlert)
    if (MSDistribute.responds(to: sharedInstanceSelector)) {
      let distributeInstance = MSDistribute.perform(sharedInstanceSelector).takeUnretainedValue()
      if (distributeInstance.responds(to: disabledAlertSelector)) {
        _ = distributeInstance.perform(disabledAlertSelector)
      }
    }
#endif
  }

  func showCustomConfirmationAlert() {
#if canImport(AppCenterDistribute)
    let sharedInstanceSelector = #selector(Selectors.sharedInstance)
    let delegateSelector = #selector(Selectors.delegate)
    let releaseDetails = MSReleaseDetails();
    releaseDetails.version = "10";
    releaseDetails.shortVersion = "1.0";
    if (MSDistribute.responds(to: sharedInstanceSelector)) {
      let distributeInstance = MSDistribute.perform(sharedInstanceSelector).takeUnretainedValue()
      let distriuteDelegate = distributeInstance.perform(delegateSelector).takeUnretainedValue()
      _ = distriuteDelegate.distribute?(distributeInstance as? MSDistribute, releaseAvailableWith: releaseDetails)
    }
#endif
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
}
