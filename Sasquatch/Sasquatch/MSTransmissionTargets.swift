import Foundation

class MSTransmissionTargets {

  static let shared = MSTransmissionTargets.init()
  var transmissionTargets: [String: MSAnalyticsTransmissionTarget]!
  private var sendsAnalyticsEvents: [String: Bool]!
  private let defaultTargetKey = "defaultTargetKey"

  private init() {

    // Set up all transmission targets and associated mappings. The three targets and their tokens are hard coded.
    transmissionTargets = [String: MSAnalyticsTransmissionTarget]()
    sendsAnalyticsEvents = [String: Bool]()

    // Default target.
    sendsAnalyticsEvents[defaultTargetKey] = true

    // Parent target.
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    let objCRuntimeToken = kMSPuppetRuntimeTargetToken
    #else
    let objCRuntimeToken = kMSObjCRuntimeTargetToken
    #endif
    let parentTargetToken = appName == "SasquatchSwift" ? kMSSwiftRuntimeTargetToken : objCRuntimeToken
    let parentTarget = MSAnalytics.transmissionTarget(forToken: parentTargetToken)
    transmissionTargets[parentTargetToken] = parentTarget
    sendsAnalyticsEvents[parentTargetToken] = true

    // Child 1 target.
    let childTarget1 = parentTarget.transmissionTarget(forToken: kMSTargetToken1)
    transmissionTargets[kMSTargetToken1] = childTarget1
    sendsAnalyticsEvents[kMSTargetToken1] = true

    // Child 2 target.
    let childTarget2 = parentTarget.transmissionTarget(forToken: kMSTargetToken2)
    transmissionTargets[kMSTargetToken2] = childTarget2
    sendsAnalyticsEvents[kMSTargetToken2] = true
  }

  func setShouldSendAnalyticsEvents(targetToken: String, enabledState: Bool) {
    sendsAnalyticsEvents[targetToken] = enabledState
  }

  func targetShouldSendAnalyticsEvents(targetToken: String) -> Bool {
    return sendsAnalyticsEvents[targetToken]!
  }

  func setShouldDefaultTargetSendAnalyticsEvents(enabledState: Bool) {
    sendsAnalyticsEvents[defaultTargetKey] = enabledState
  }

  func defaultTargetShouldSendAnalyticsEvents() -> Bool {
    return sendsAnalyticsEvents[defaultTargetKey]!
  }
}
