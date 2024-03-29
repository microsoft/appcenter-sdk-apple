// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

private let kDefaultTargetKey = "defaultTargetKey"

class MSTransmissionTargets {
  static let shared = MSTransmissionTargets.init()

  var transmissionTargets = [String: AnalyticsTransmissionTarget]()
  let defaultTransmissionTargetIsEnabled: Bool
  private var sendsAnalyticsEvents = [String: Bool]()

  private init() {

    // Default target.
    let startTarget = UserDefaults.standard.integer(forKey: kMSStartTargetKey)
    let startMode = MSMainViewController.StartupMode.allValues[startTarget]
    defaultTransmissionTargetIsEnabled =
      startMode == MSMainViewController.StartupMode.OneCollector ||
      startMode == MSMainViewController.StartupMode.Both
    sendsAnalyticsEvents[kDefaultTargetKey] = true

    // Parent target.
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    let parentTargetToken = appName.contains("SasquatchSwift") ? Constants.kMSSwiftRuntimeTargetToken : Constants.kMSObjCRuntimeTargetToken
    let parentTarget = Analytics.transmissionTarget(forToken: parentTargetToken)
    transmissionTargets[parentTargetToken] = parentTarget
    sendsAnalyticsEvents[parentTargetToken] = true

    // Child 1 target.
    let childTarget1 = parentTarget.transmissionTarget(forToken: Constants.kMSTargetToken1)
    transmissionTargets[Constants.kMSTargetToken1] = childTarget1
    sendsAnalyticsEvents[Constants.kMSTargetToken1] = true

    // Child 2 target.
    let childTarget2 = parentTarget.transmissionTarget(forToken: Constants.kMSTargetToken2)
    transmissionTargets[Constants.kMSTargetToken2] = childTarget2
    sendsAnalyticsEvents[Constants.kMSTargetToken2] = true
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
