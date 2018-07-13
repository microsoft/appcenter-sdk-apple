import UIKit

class MSTransmissionTargetsViewController: UITableViewController {
  var appCenter: AppCenterDelegate!

  private class MSTransmissionTargetSection: NSObject {
    var target: MSAnalyticsTransmissionTarget?
    var analyticsEnabled: Bool?
    var token: String?
    var headerText: String?
    var footerText: String?
  }

  private var transmissionTargetSections: [MSTransmissionTargetSection]?
  private let kEnabledSwitchCellId = "enabledswitchcell"
  private let kAnalyticsSwitchCellId = "analyticsswitchcell"
  private let kTokenCellId = "tokencell"

  override func viewDidLoad() {
    super.viewDidLoad()

    // Default target section.
    let defaultTargetSection = MSTransmissionTargetSection()
    defaultTargetSection.headerText = "Default Transmission Target"
    defaultTargetSection.footerText = "This is the default transmission target. It is automatically enabled at launch time."
    defaultTargetSection.analyticsEnabled = true

    // Runtime target section.
    let runtimeTargetSection = MSTransmissionTargetSection()
    runtimeTargetSection.headerText = "Runtime Transmission Target"
    runtimeTargetSection.footerText = "This transmission target must be enabled at runtime. It is the parent of the two transmission targets below."
    runtimeTargetSection.analyticsEnabled = true

    // Child 1.
    let child1TargetSection = MSTransmissionTargetSection()
    child1TargetSection.headerText = "Child Transmission Target 1"
    child1TargetSection.analyticsEnabled = true

    // Child 2.
    let child2TargetSection = MSTransmissionTargetSection()
    child2TargetSection.headerText = "Child Transmission Target 2"
    child2TargetSection.analyticsEnabled = true

    // The ordering of these target sections is important so they are displayed in the right order.
    transmissionTargetSections = [defaultTargetSection, runtimeTargetSection, child1TargetSection, child2TargetSection]
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 3
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch indexPath.row {
    case 0: // Enabled cell
      let cell = tableView.dequeueReusableCell(withIdentifier: kEnabledSwitchCellId)!
      let switcher: UISwitch? = getSubviewFromCell(cell)
      switcher?.isOn = true //TODO use the enabled state of the target.
      return cell
    case 1: // Analytics enabled cell
      return tableView.dequeueReusableCell(withIdentifier: kAnalyticsSwitchCellId)!
    case 2: // Token cell
      return tableView.dequeueReusableCell(withIdentifier: kTokenCellId)!
    default:
      return super.tableView(tableView, cellForRowAt: indexPath)
    }
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
}
