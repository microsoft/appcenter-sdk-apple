import MobileCenter
import MobileCenterAnalytics

/**
 * MobileCenterDelegate implementation in Swift.
 */
class MobileCenterDelegateSwift: MobileCenterDelegate {

  //MARK: MSMobileCenter section.
  func isMobileCenterEnabled() -> Bool{
    return MSMobileCenter.isEnabled()
  }
  func setMobileCenterEnabled(_ isEnabled: Bool){
    MSMobileCenter.setEnabled(isEnabled)
  }
  func installId() -> String{
    return MSMobileCenter.installId().uuidString
  }
  func appSecret() -> String{
    // TODO: Uncomment when appSecret is moved from internal to public.
    // return MSMobileCenter.sharedInstance().appSecret()
    return "Internal"
  }
  func logUrl() -> String{
    // TODO: Uncomment when logUrl is moved from internal to public.
    // return MSMobileCenter.sharedInstance().logUrl()
    return "Internal"
  }
  func isDebuggerAttached() -> Bool{
    return MSMobileCenter.isDebuggerAttached()
  }

  //MARK: MSAnalytics section.
  func isAnalyticsEnabled() -> Bool{
    return MSAnalytics.isEnabled()
  }

  func setAnalyticsEnabled(_ isEnabled: Bool){
    MSAnalytics.setEnabled(isEnabled)
  }

  func trackEvent(_ eventName: String){
    MSAnalytics.trackEvent(eventName)
  }

  func trackEvent(_ eventName: String, withProperties properties: Dictionary<String, String>){
    MSAnalytics.trackEvent(eventName, withProperties: properties)
  }

  func trackPage(_ eventName: String){
    // TODO: Uncomment when trackPage is moved from internal to public.
    // MSAnalytics.trackPage(eventName)
  }

  func trackPage(_ eventName: String, withProperties properties: Dictionary<String, String>){
    // TODO: Uncomment when trackPage is moved from internal to public.
    // MSAnalytics.trackPage(eventName, withProperties: properties)
  }

  //MARK: MSCrashes section.
  // TODO: Uncomment when Crashes will allowed for tvOS.

//  func isCrashesEnabled() -> Bool{
//    return MSCrashes.isEnabled()
//  }
//
//  func setCrashesEnabled(_ isEnabled: Bool){
//    MSCrashes.setEnabled(isEnabled)
//  }
//
//  func hasCrashedInLastSession() -> Bool{
//    return MSCrashes.hasCrashedInLastSession()
//  }
//
//  func generateTestCrash() {
//    MSCrashes.generateTestCrash()
//  }

  //MARK: Last crash report section.
//  func lastCrashReportIncidentIdentifier() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.incidentIdentifier
//  }
//  func lastCrashReportReporterKey() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.reporterKey
//  }
//  func lastCrashReportSignal() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.signal
//  }
//  func lastCrashReportExceptionName() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.exceptionName
//  }
//  func lastCrashReportExceptionReason() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.exceptionReason
//  }
//  func lastCrashReportAppStartTimeDescription() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.appStartTime.description
//  }
//  func lastCrashReportAppErrorTimeDescription() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.appErrorTime.description
//  }
//  func lastCrashReportAppProcessIdentifier() -> UInt{
//    return (MSCrashes.lastSessionCrashReport()?.appProcessIdentifier)!
//  }
//  func lastCrashReportIsAppKill() -> Bool{
//    return (MSCrashes.lastSessionCrashReport()?.isAppKill())!
//  }
//  func lastCrashReportDeviceModel() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.model
//  }
//  func lastCrashReportDeviceOemName() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.oemName
//  }
//  func lastCrashReportDeviceOsName() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.osName
//  }
//  func lastCrashReportDeviceOsVersion() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.osVersion
//  }
//  func lastCrashReportDeviceOsBuild() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.osBuild
//  }
//  func lastCrashReportDeviceLocale() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.locale
//  }
//  func lastCrashReportDeviceTimeZoneOffset() -> NSNumber?{
//    return MSCrashes.lastSessionCrashReport()?.device.timeZoneOffset
//  }
//  func lastCrashReportDeviceScreenSize() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.screenSize
//  }
//  func lastCrashReportDeviceAppVersion() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.appVersion
//  }
//  func lastCrashReportDeviceAppBuild() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.appBuild
//  }
//  func lastCrashReportDeviceCarrierName() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.carrierName
//  }
//  func lastCrashReportDeviceCarrierCountry() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.carrierCountry
//  }
//  func lastCrashReportDeviceAppNamespace() -> String?{
//    return MSCrashes.lastSessionCrashReport()?.device.appNamespace
//  }
}
