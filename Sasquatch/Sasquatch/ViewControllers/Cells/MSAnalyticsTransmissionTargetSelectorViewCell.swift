// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

@objc(MSAnalyticsTransmissionTargetSelectorViewCell) class MSAnalyticsTransmissionTargetSelectorViewCell: UITableViewCell {

  @IBOutlet weak var transmissionTargetSelector: UISegmentedControl!
  
  public var didSelectTransmissionTarget: (() -> Void)?
  public var transmissionTargetMapping: [String]?

  override func awakeFromNib() {
    super.awakeFromNib()
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    let runtimeToken: String = appName.contains("SasquatchSwift") ? Constants.kMSSwiftRuntimeTargetToken : Constants.kMSObjCRuntimeTargetToken
    transmissionTargetMapping = [Constants.kMSTargetToken1, Constants.kMSTargetToken2, runtimeToken]
    didSelectTransmissionTarget = {() in}
    transmissionTargetSelector.addTarget(self, action: #selector(onSegmentSelected), for: .valueChanged)
  }

  public func selectedTransmissionTarget() -> String! {
    return transmissionTargetMapping![transmissionTargetSelector.selectedSegmentIndex]
  }

  @objc func onSegmentSelected() {
    didSelectTransmissionTarget?()
  }
}
