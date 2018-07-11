import UIKit

@objc(MSAnalyticsTranmissionTargetSelectorViewCell) class MSAnalyticsTranmissionTargetSelectorViewCell: UITableViewCell {

@IBOutlet weak var transmissionTargetSelector: UISegmentedControl!

  public var didSelectTransmissionTarget: (() -> Void)?
  public let eventPropertiesIdentifier = "Event Arguments"

  override func awakeFromNib() {
    super.awakeFromNib()
    didSelectTransmissionTarget = {_ in}
    transmissionTargetSelector.addTarget(self, action: #selector(onSegmentSelected), for: .valueChanged)
  }

  public func selectedTransmissionTarget() -> String! {
    return transmissionTargetSelector.titleForSegment(at: transmissionTargetSelector.selectedSegmentIndex)
  }

  public func transmissionTargets() -> [String]! {
    var targets = [String].init()
    for index in 0...transmissionTargetSelector.numberOfSegments - 1 {
      targets.append(transmissionTargetSelector.titleForSegment(at: index)!)
    }
    return targets
  }

  func onSegmentSelected() {
    didSelectTransmissionTarget?()
  }
}
