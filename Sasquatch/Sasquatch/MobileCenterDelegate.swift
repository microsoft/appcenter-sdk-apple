protocol MobileCenterDelegate {
    func hasCrashedInLastSession() -> Bool
    func isAnalyticsEnabled() -> Bool
    func isCrashesEnabled() -> Bool
    func isDistributeEnabled() -> Bool
    func setAnalyticsEnabled(_ isEnabled: Bool)
    func setCrashesEnabled(_ isEnabled: Bool)
    func setDistributeEnabled(_ isEnabled: Bool)
    func isDebuggerAttached() -> Bool
    func generateTestCrash()
    func trackEvent(_ eventName: String)
    func trackEvent(_ eventName: String, withProperties: Dictionary<String, String>)
    
    //Lasr crash report section
    func lastCrashReportIncidentIdentifier() -> String?
    func lastCrashReportReporterKey() -> String?
    func lastCrashReportSignal() -> String?
    func lastCrashReportExceptionName() -> String?
    func lastCrashReportExceptionReason() -> String?
    func lastCrashReportAppStartTimeDescription() -> String?
    func lastCrashReportAppErrorTimeDescription() -> String?
    func lastCrashReportAppProcessIdentifier() -> UInt?
    func lastCrashReportIsAppKill() -> Bool?
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
