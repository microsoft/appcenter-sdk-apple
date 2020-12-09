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
  func sharedInstance() -> Distribute
  func checkForUpdate()
  func showConfirmationAlert(_ releaseDetails: ReleaseDetails)
  func showDistributeDisabledAlert()
  func delegate() -> DistributeDelegate
  func closeApp()
}
#endif

/**
 * AppCenterDelegate implementation in Swift.
 */
class AppCenterDelegateSwift: AppCenterDelegate {

  // AppCenter section.
  func isAppCenterEnabled() -> Bool {
    return AppCenter.enabled
  }

  func setAppCenterEnabled(_ isEnabled: Bool) {
    AppCenter.enabled = isEnabled
  }

  func setCustomProperties(_ customProperties: CustomProperties) {
    AppCenter.setCustomProperties(customProperties)
  }

  func installId() -> String {
    return AppCenter.installId.uuidString
  }

  func appSecret() -> String {
#if !targetEnvironment(macCatalyst)
    return kMSSwiftAppSecret
#else
    return kMSSwiftCatalystAppSecret
#endif
  }

  func setLogUrl(_ logUrl: String?) {
    AppCenter.logUrl = logUrl;
  }

  func sdkVersion() -> String {
    return AppCenter.sdkVersion
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
  
  func setCountryCode(_ countryCode: String?) {
    AppCenter.countryCode = countryCode;
  }

  // Modules section.
  func isAnalyticsEnabled() -> Bool {
    return Analytics.enabled
  }

  func isCrashesEnabled() -> Bool {
    return Crashes.enabled
  }

  func isDistributeEnabled() -> Bool {
#if canImport(AppCenterDistribute)
    return Distribute.enabled
#else
    return false
#endif
  }

  func setAnalyticsEnabled(_ isEnabled: Bool) {
    Analytics.enabled = isEnabled
  }

  func setCrashesEnabled(_ isEnabled: Bool) {
    Crashes.enabled = isEnabled
  }

  func setDistributeEnabled(_ isEnabled: Bool) {
#if canImport(AppCenterDistribute)
    Distribute.enabled = isEnabled
#endif
  }

  // Analytics section.
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

  #warning("TODO: Uncomment when trackPage is moved from internal to public")
  func trackPage(_ pageName: String) {
    // Analytics.trackPage(pageName)
  }

  #warning("TODO: Uncomment when trackPage is moved from internal to public")
  func trackPage(_ pageName: String, withProperties properties: Dictionary<String, String>) {
    // Analytics.trackPage(pageName, withProperties: properties)
  }

  func resume() {
    Analytics.resume()
  }

  func pause() {
    Analytics.pause()
  }

  // Crashes section.
  func hasCrashedInLastSession() -> Bool {
    return Crashes.hasCrashedInLastSession
  }
  
  func hasReceivedMemoryWarningInLastSession() -> Bool {
    return Crashes.hasReceivedMemoryWarningInLastSession
  }
  
  func generateTestCrash() {
    Crashes.generateTestCrash()
  }

  // Distribute section.

  func checkForUpdate() {
#if canImport(AppCenterDistribute)
    Distribute.checkForUpdate()
#endif
  }

  func showConfirmationAlert() {
#if canImport(AppCenterDistribute)
    let sharedInstanceSelector = #selector(Selectors.sharedInstance)
    let confirmationAlertSelector = #selector(Selectors.showConfirmationAlert(_:))
    let releaseDetails = ReleaseDetails();
    releaseDetails.version = "10";
    releaseDetails.shortVersion = "1.0";
    if (Distribute.responds(to: sharedInstanceSelector)) {
      let distributeInstance = Distribute.perform(sharedInstanceSelector).takeUnretainedValue()
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
    if (Distribute.responds(to: sharedInstanceSelector)) {
      let distributeInstance = Distribute.perform(sharedInstanceSelector).takeUnretainedValue()
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
    let releaseDetails = ReleaseDetails();
    releaseDetails.version = "10";
    releaseDetails.shortVersion = "1.0";
    if (Distribute.responds(to: sharedInstanceSelector)) {
      let distributeInstance = Distribute.perform(sharedInstanceSelector).takeUnretainedValue()
      let distriuteDelegate = distributeInstance.perform(delegateSelector).takeUnretainedValue()
      _ = distriuteDelegate.distribute?(distributeInstance as! Distribute, releaseAvailableWith: releaseDetails)
    }
#endif
  }

  func closeApp() {
#if canImport(AppCenterDistribute)
    let sharedInstanceSelector = #selector(Selectors.sharedInstance)
    let closeAppSelector = #selector(Selectors.closeApp)
    if (Distribute.responds(to: sharedInstanceSelector)) {
      let distributeInstance = Distribute.perform(sharedInstanceSelector).takeUnretainedValue()
      if (distributeInstance.responds(to: closeAppSelector)) {
        DispatchQueue.global().async {
          _ = distributeInstance.perform(closeAppSelector)
        }
      }
    }
#endif
  }

  // Last crash report section.
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
}
