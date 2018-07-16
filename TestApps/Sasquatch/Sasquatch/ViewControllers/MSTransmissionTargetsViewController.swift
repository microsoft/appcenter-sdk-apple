import UIKit

class MSTransmissionTargetsViewController: UITableViewController {
  var appCenter: AppCenterDelegate!

  private class MSTransmissionTargetSection: NSObject {
    var token: String?
    var headerText: String?
    var footerText: String?

    func getTransmissionTarget() -> MSAnalyticsTransmissionTarget {
      return MSTransmissionTargets.shared.transmissionTargets[token!]!
    }

    func shouldSendAnalytics() -> Bool {
      return MSTransmissionTargets.shared.targetShouldSendAnalyticsEvents(targetToken: token!)
    }

    func setShouldSendAnalytics(enabledState: Bool) {
      MSTransmissionTargets.shared.setShouldSendAnalyticsEvents(targetToken: token!, enabledState: enabledState)
    }
  }

  private var transmissionTargetSections: [MSTransmissionTargetSection]?
  private let kEnabledSwitchCellId = "enabledswitchcell"
  private let kAnalyticsSwitchCellId = "analyticsswitchcell"
  private let kTokenCellId = "tokencell"
  private let kTokenDisplayLabelTag = 1

  override func viewDidLoad() {
    super.viewDidLoad()

    // Runtime target section.
    let runtimeTargetSection = MSTransmissionTargetSection()
    runtimeTargetSection.headerText = "Runtime Transmission Target"
    runtimeTargetSection.footerText = "This transmission target must be enabled at runtime. It is the parent of the two transmission targets below."
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    runtimeTargetSection.token = appName == "SasquatchSwift" ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken

    // Child 1.
    let child1TargetSection = MSTransmissionTargetSection()
    child1TargetSection.headerText = "Child Transmission Target 1"
    child1TargetSection.token = kMSTargetToken1

    // Child 2.
    let child2TargetSection = MSTransmissionTargetSection()
    child2TargetSection.headerText = "Child Transmission Target 2"
    child2TargetSection.token = kMSTargetToken2

    // The ordering of these target sections is important so they are displayed in the right order.
    transmissionTargetSections = [runtimeTargetSection, child1TargetSection, child2TargetSection]
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 3
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let section = transmissionTargetSections![indexPath.section]
    switch indexPath.row {
    case 0: // Enabled cell
      let cell = tableView.dequeueReusableCell(withIdentifier: kEnabledSwitchCellId)!
      let switcher: UISwitch? = getSubviewFromCell(cell)
      switcher?.isOn = section.getTransmissionTarget().isEnabled()
      switcher?.addTarget(self, action: #selector(targetEnabledSwitchValueChanged), for: .valueChanged)
      return cell
    case 1: // Analytics enabled cell
      let cell = tableView.dequeueReusableCell(withIdentifier: kAnalyticsSwitchCellId)!
      let switcher: UISwitch? = getSubviewFromCell(cell)
      switcher?.isOn = section.shouldSendAnalytics()
      switcher?.addTarget(self, action: #selector(targetShouldSendAnalyticsSwitchValueChanged), for: .valueChanged)
      return cell
    case 2: // Token cell
      let cell = tableView.dequeueReusableCell(withIdentifier: kTokenCellId)!
      let label: UILabel? = getSubviewFromCell(cell, withTag:kTokenDisplayLabelTag)
      label?.text = section.token
      return cell
    default:
      return super.tableView(tableView, cellForRowAt: indexPath)
    }
  }

  func targetEnabledSwitchValueChanged(sender: UISwitch!) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    section.getTransmissionTarget().setEnabled(sender!.isOn)
    if (sectionIndex == 0) {
      for childSectionIndex in 1...2 {
        let childCell = tableView.cellForRow(at: IndexPath(row: 0, section: childSectionIndex))
        let childSwitch: UISwitch? = getSubviewFromCell(childCell!)
        let childTarget = transmissionTargetSections![childSectionIndex].getTransmissionTarget()
        childSwitch!.setOn(childTarget.isEnabled(), animated: true)
        childSwitch?.isEnabled = sender!.isOn
      }
    }
  }

  func targetShouldSendAnalyticsSwitchValueChanged(sender: UISwitch!) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    section.setShouldSendAnalytics(enabledState: sender!.isOn)
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return transmissionTargetSections!.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return transmissionTargetSections![section].headerText
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    return transmissionTargetSections![section].footerText
  }

  private func getSubviewFromCell<T: UIView>(_ cell: UITableViewCell, withTag tag:Int = 0) -> T? {
    for subview in cell.contentView.subviews {
      if  (subview.tag == tag) && (subview is T) {
        return subview as? T
      }
    }
    return nil
  }

  func getCellSection(forView view: UIView) -> Int {
    let cell = view.superview!.superview as! UITableViewCell
    let indexPath = tableView.indexPath(for: cell)!
    return indexPath.section
  }
}
