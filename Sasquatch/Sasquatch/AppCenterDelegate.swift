// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#if !ACTIVE_COMPILATION_CONDITION_PUPPET
import AppCenter
import AppCenterAnalytics
#endif

/**
 * Protocol for interacting with AppCenter SDK.
 * Swift and Objective C implement this protocol
 * to show usage of AppCenter SDK in a language specific way.
 */
@objc protocol AppCenterDelegate {

  // AppCenter section.
  func isAppCenterEnabled() -> Bool
  func setAppCenterEnabled(_ isEnabled: Bool)
  func setCustomProperties(_ customProperties: CustomProperties)
  func installId() -> String
  func appSecret() -> String
  func sdkVersion() -> String
  func isDebuggerAttached() -> Bool
  func startAnalyticsFromLibrary()
  func setUserId(_ userId: String?)
  func setLogUrl(_ logUrl: String?)
  func setCountryCode(_ countryCode: String?)
  func isNetworkRequestsAllowed() -> Bool
  func setNetworkRequestsAllowed(_ isAllowed: Bool)
  
  // Modules section.
  func isAnalyticsEnabled() -> Bool
  func isCrashesEnabled() -> Bool
  func isDistributeEnabled() -> Bool
  func setAnalyticsEnabled(_ isEnabled: Bool)
  func setCrashesEnabled(_ isEnabled: Bool)
  func setDistributeEnabled(_ isEnabled: Bool)

  // Analytics section.
  func trackEvent(_ eventName: String)
  func trackEvent(_ eventName: String, withProperties: Dictionary<String, String>)
  func trackEvent(_ eventName: String, withProperties: Dictionary<String, String>, flags: Flags)
  func trackEvent(_ eventName: String, withTypedProperties: EventProperties)
  func trackEvent(_ eventName: String, withTypedProperties: EventProperties?, flags: Flags)
  func trackPage(_ pageName: String)
  func trackPage(_ pageName: String, withProperties: Dictionary<String, String>)
  func resume()
  func pause()
  
  // Crashes section.
  func hasCrashedInLastSession() -> Bool
  func hasReceivedMemoryWarningInLastSession() -> Bool
  func generateTestCrash()
  
  // Distribute section.
  func showConfirmationAlert()
  func checkForUpdate()
  func showDistributeDisabledAlert()
  func showCustomConfirmationAlert()
  func closeApp()

  // Last crash report section.
  func lastCrashReportIncidentIdentifier() -> String?
  func lastCrashReportReporterKey() -> String?
  func lastCrashReportSignal() -> String?
  func lastCrashReportExceptionName() -> String?
  func lastCrashReportExceptionReason() -> String?
  func lastCrashReportAppStartTimeDescription() -> String?
  func lastCrashReportAppErrorTimeDescription() -> String?
  func lastCrashReportAppProcessIdentifier() -> UInt
  func lastCrashReportIsAppKill() -> Bool
  func lastCrashReportDeviceModel() -> String?
  func lastCrashReportDeviceOemName() -> String?
  func lastCrashReportDeviceOsName() -> String?
  func lastCrashReportDeviceOsVersion() -> String?
  func lastCrashReportDeviceOsBuild() -> String?
  func lastCrashReportDeviceLocale() -> String?
  func lastCrashReportDeviceTimeZoneOffset() -> NSNumber?
  func lastCrashReportDeviceScreenSize() -> String?
  func lastCrashReportDeviceAppVersion() -> String?
  func lastCrashReportDeviceAppBuild() -> String?
  func lastCrashReportDeviceCarrierName() -> String?
  func lastCrashReportDeviceCarrierCountry() -> String?
  func lastCrashReportDeviceAppNamespace() -> String?
}
