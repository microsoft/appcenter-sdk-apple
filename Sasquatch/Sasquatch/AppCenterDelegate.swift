// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#if !ACTIVE_COMPILATION_CONDITION_PUPPET
import AppCenter
import AppCenterAnalytics
import AppCenterAuth
import AppCenterData
#endif

/**
 * Protocol for interacting with AppCenter SDK.
 * Swift and Objective C implement this protocol
 * to show usage of AppCenter SDK in a language specific way.
 */
@objc protocol AppCenterDelegate {

  // MSAppCenter section.
  func isAppCenterEnabled() -> Bool
  func setAppCenterEnabled(_ isEnabled: Bool)
  func setCustomProperties(_ customProperties: MSCustomProperties)
  func installId() -> String
  func appSecret() -> String
  func sdkVersion() -> String
  func isDebuggerAttached() -> Bool
  func startAnalyticsFromLibrary()
  func setUserId(_ userId: String?)
  func setLogUrl(_ logUrl: String?)
  func setCountryCode(_ countryCode: String?)
  
  // Modules section.
  func isAnalyticsEnabled() -> Bool
  func isCrashesEnabled() -> Bool
  func isDistributeEnabled() -> Bool
  func isAuthEnabled() -> Bool
  func isPushEnabled() -> Bool
  func setAnalyticsEnabled(_ isEnabled: Bool)
  func setCrashesEnabled(_ isEnabled: Bool)
  func setDistributeEnabled(_ isEnabled: Bool)
  func setAuthEnabled(_ isEnabled: Bool)
  func setPushEnabled(_ isEnabled: Bool)

  // MSAnalytics section.
  func trackEvent(_ eventName: String)
  func trackEvent(_ eventName: String, withProperties: Dictionary<String, String>)
  func trackEvent(_ eventName: String, withProperties: Dictionary<String, String>, flags: MSFlags)
  func trackEvent(_ eventName: String, withTypedProperties: MSEventProperties)
  func trackEvent(_ eventName: String, withTypedProperties: MSEventProperties?, flags: MSFlags)
  func trackPage(_ pageName: String)
  func trackPage(_ pageName: String, withProperties: Dictionary<String, String>)
  func resume()
  func pause()
  
  // MSCrashes section.
  func hasCrashedInLastSession() -> Bool
  func generateTestCrash()
  
  // MSDistribute section.
  func showConfirmationAlert()
  func showDistributeDisabledAlert()
  func showCustomConfirmationAlert()

  // MSAuth section.
  func signIn(_ completionHandler: @escaping (_ signInInformation:MSUserInformation?, _ error:Error?) -> Void)
  func signOut()
  
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
  
  // MSData section
  func listDocumentsWithPartition(_ partitionName: String, documentType: AnyClass, completionHandler: @escaping (_ paginatedDocuments:MSPaginatedDocuments) -> Void)
  func createDocumentWithPartition(_ partitionName: String, documentId: String, document: MSDictionaryDocument, writeOptions: MSWriteOptions, completionHandler: @escaping (_ document:MSDocumentWrapper) -> Void)
  func replaceDocumentWithPartition(_ partitionName: String, documentId: String, document: MSDictionaryDocument, writeOptions: MSWriteOptions, completionHandler: @escaping (_ document:MSDocumentWrapper) -> Void)
  func deleteDocumentWithPartition(_ partitionName: String, documentId: String)
}
