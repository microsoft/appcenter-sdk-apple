// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

private let kDefaultTargetKey = "defaultTargetKey"

class TransmissionTargets {
  static let shared = TransmissionTargets.init()
  static let startTarget = UserDefaults.standard.integer(forKey: kMSStartTargetKey)
  var transmissionTargets = [String: AnalyticsTransmissionTarget]()
  private var sendsAnalyticsEvents = [String: Bool]()
  enum StartupMode: Int {
    case appCenter
    case oneCollector
    case both
    case none
    case skip
  }
    
  static let defaultTransmissionTargetWasEnabled: Bool = TransmissionTargets.startTarget == StartupMode.oneCollector.rawValue || startTarget == StartupMode.both.rawValue

  private init() {

    // Default target.
    sendsAnalyticsEvents[kDefaultTargetKey] = true

    // Parent target.
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    let parentTargetToken = appName.contains("SasquatchMacSwift") ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken
    let parentTarget = Analytics.transmissionTarget(forToken: parentTargetToken)
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
    sendsAnalyticsEvents[kDefaultTargetKey] = enabledState
  }

  func defaultTargetShouldSendAnalyticsEvents() -> Bool {
    return sendsAnalyticsEvents[kDefaultTargetKey]!
  }
}
