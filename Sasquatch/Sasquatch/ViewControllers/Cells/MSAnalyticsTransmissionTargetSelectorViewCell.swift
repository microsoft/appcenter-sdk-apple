import UIKit

@objc(MSAnalyticsTransmissionTargetSelectorViewCell) class MSAnalyticsTransmissionTargetSelectorViewCell: UITableViewCell {

  @IBOutlet weak var transmissionTargetSelector: UISegmentedControl!
  
  public var didSelectTransmissionTarget: (() -> Void)?
  public var transmissionTargetMapping: [String]?

  override func awakeFromNib() {
    super.awakeFromNib()
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    let objCRuntimeToken = kMSPuppetRuntimeTargetToken
    #else
    let objCRuntimeToken = kMSObjCRuntimeTargetToken
    #endif
    let runtimeToken: String = appName == "SasquatchSwift" ? kMSSwiftRuntimeTargetToken : objCRuntimeToken
    transmissionTargetMapping = [kMSTargetToken1, kMSTargetToken2, runtimeToken]
    didSelectTransmissionTarget = {_ in}
    transmissionTargetSelector.addTarget(self, action: #selector(onSegmentSelected), for: .valueChanged)
  }

  public func selectedTransmissionTarget() -> String! {
    return transmissionTargetMapping![transmissionTargetSelector.selectedSegmentIndex]
  }

  func onSegmentSelected() {
    didSelectTransmissionTarget?()
  }
}
