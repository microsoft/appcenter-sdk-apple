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
  func sharedInstance() -> MSACDistribute
  func checkForUpdate()
  func showConfirmationAlert(_ releaseDetails: MSACReleaseDetails)
  func showDistributeDisabledAlert()
  func delegate() -> MSACDistributeDelegate
}
#endif
#if canImport(AppCenterPush)
import AppCenterPush
#endif

/**
 * AppCenterDelegate implementation in Swift.
 */
class AppCenterDelegateSwift: AppCenterDelegate {

  // MSACAppCenter section.
  func isAppCenterEnabled() -> Bool {
    return MSACAppCenter.isEnabled()
  }

  func setAppCenterEnabled(_ isEnabled: Bool) {
    MSACAppCenter.setEnabled(isEnabled)
  }

  func setCustomProperties(_ customProperties: MSACCustomProperties) {
    MSACAppCenter.setCustomProperties(customProperties)
  }

  func installId() -> String {
    return MSACAppCenter.installId().uuidString
  }

  func appSecret() -> String {
#if !targetEnvironment(macCatalyst)
    return kMSSwiftAppSecret
#else
    return kMSSwiftCatalystAppSecret
#endif
  }

  func setLogUrl(_ logUrl: String?) {
    MSACAppCenter.setLogUrl(logUrl);
  }

  func sdkVersion() -> String {
    return MSACAppCenter.sdkVersion()
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
  
  func setCountryCode(_ countryCode: String?) {
    MSACAppCenter.setCountryCode(countryCode);
  }

  // Modules section.
  func isAnalyticsEnabled() -> Bool {
    return MSACAnalytics.isEnabled()
  }

  func isCrashesEnabled() -> Bool {
    return MSACCrashes.isEnabled()
  }

  func isDistributeEnabled() -> Bool {
#if canImport(AppCenterDistribute)
    return MSACDistribute.isEnabled()
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
    MSACAnalytics.setEnabled(isEnabled)
  }

  func setCrashesEnabled(_ isEnabled: Bool) {
    MSACCrashes.setEnabled(isEnabled)
  }

  func setDistributeEnabled(_ isEnabled: Bool) {
#if canImport(AppCenterDistribute)
    MSACDistribute.setEnabled(isEnabled)
#endif
  }

  func setPushEnabled(_ isEnabled: Bool) {
#if canImport(AppCenterPush)
    MSPush.setEnabled(isEnabled)
#endif
  }

  // MSACAnalytics section.
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

  #warning("TODO: Uncomment when trackPage is moved from internal to public")
  func trackPage(_ pageName: String) {
    // MSACAnalytics.trackPage(pageName)
  }

  #warning("TODO: Uncomment when trackPage is moved from internal to public")
  func trackPage(_ pageName: String, withProperties properties: Dictionary<String, String>) {
    // MSACAnalytics.trackPage(pageName, withProperties: properties)
  }

  func resume() {
    MSACAnalytics.resume()
  }

  func pause() {
    MSACAnalytics.pause()
  }

  // MSACCrashes section.
  func hasCrashedInLastSession() -> Bool {
    return MSACCrashes.hasCrashedInLastSession()
  }
  
  func hasReceivedMemoryWarningInLastSession() -> Bool {
    return MSACCrashes.hasReceivedMemoryWarningInLastSession()
  }
  
  func generateTestCrash() {
    MSACCrashes.generateTestCrash()
  }

  // MSACDistribute section.

  func checkForUpdate() {
#if canImport(AppCenterDistribute)
    MSACDistribute.checkForUpdate()
#endif
  }

  func showConfirmationAlert() {
#if canImport(AppCenterDistribute)
    let sharedInstanceSelector = #selector(Selectors.sharedInstance)
    let confirmationAlertSelector = #selector(Selectors.showConfirmationAlert(_:))
    let releaseDetails = MSACReleaseDetails();
    releaseDetails.version = "10";
    releaseDetails.shortVersion = "1.0";
    if (MSACDistribute.responds(to: sharedInstanceSelector)) {
      let distributeInstance = MSACDistribute.perform(sharedInstanceSelector).takeUnretainedValue()
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
    if (MSACDistribute.responds(to: sharedInstanceSelector)) {
      let distributeInstance = MSACDistribute.perform(sharedInstanceSelector).takeUnretainedValue()
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
    let releaseDetails = MSACReleaseDetails();
    releaseDetails.version = "10";
    releaseDetails.shortVersion = "1.0";
    if (MSACDistribute.responds(to: sharedInstanceSelector)) {
      let distributeInstance = MSACDistribute.perform(sharedInstanceSelector).takeUnretainedValue()
      let distriuteDelegate = distributeInstance.perform(delegateSelector).takeUnretainedValue()
      _ = distriuteDelegate.distribute?(distributeInstance as? MSACDistribute, releaseAvailableWith: releaseDetails)
    }
#endif
  }

  // Last crash report section.
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
}
