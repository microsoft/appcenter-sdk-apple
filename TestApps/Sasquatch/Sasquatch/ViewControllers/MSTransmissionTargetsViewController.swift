import UIKit

class MSTransmissionTargetsViewController: UITableViewController {
  var appCenter: AppCenterDelegate!

  private class MSTransmissionTargetSection: NSObject {
    var token: String?
    var headerText: String?
    var footerText: String?
    var isDefault = false

    func isTransmissionTargetEnabled() -> Bool {
      if isDefault {
        return UserDefaults.standard.bool(forKey: kMSOneCollectorEnabledKey)
      } else {
        return MSTransmissionTargets.shared.transmissionTargets[token!]!.isEnabled()
      }
    }

    func setTransmissionTargetEnabled(_ enabledState: Bool) {
      if isDefault {
        UserDefaults.standard.set(enabledState, forKey: kMSOneCollectorEnabledKey)
      } else {
        MSTransmissionTargets.shared.transmissionTargets[token!]!.setEnabled(enabledState)
      }
    }

    func getTransmissionTarget() -> MSAnalyticsTransmissionTarget? {
      if isDefault {
        return nil
      } else {
        return MSTransmissionTargets.shared.transmissionTargets[token!]
      }
    }

    func shouldSendAnalytics() -> Bool {
      if isDefault {
        return MSTransmissionTargets.shared.defaultTargetShouldSendAnalyticsEvents()
      } else {
        return MSTransmissionTargets.shared.targetShouldSendAnalyticsEvents(targetToken: token!)
      }
    }

    func setShouldSendAnalytics(enabledState: Bool) {
      if isDefault {
        MSTransmissionTargets.shared.setShouldDefaultTargetSendAnalyticsEvents(enabledState: enabledState)
      } else {
        MSTransmissionTargets.shared.setShouldSendAnalyticsEvents(targetToken: token!, enabledState: enabledState)
      }
    }
  }

  private var transmissionTargetSections: [MSTransmissionTargetSection]?
  private let kEnabledSwitchCellId = "enabledswitchcell"
  private let kAnalyticsSwitchCellId = "analyticsswitchcell"
  private let kTokenCellId = "tokencell"
  private let kEnabledStateIndicatorCellId = "enabledstateindicator"
  private let kTokenDisplayLabelTag = 1
  private let kEnabledCellRowIndex = 0
  private let kAnalyticsCellRowIndex = 1
  private let kTokenCellRowIndex = 2
  private let kEnabledStateIndicatorRowIndex = 2
  private let kDefaultTargetSectionIndex = 0
  private let kTargetPropertiesSectionIndex = 4
  private let kCSPropertiesSectionIndex = 5
  private var targetPropertiesSection: TargetPropertiesTableSection?
  private var csPropertiesSection: CommonSchemaPropertiesTableSection?
  private static let defaultTransmissionTargetIsEnabled = UserDefaults.standard.bool(forKey: kMSOneCollectorEnabledKey)

  override func viewDidLoad() {
    super.viewDidLoad()

    targetPropertiesSection = TargetPropertiesTableSection(tableSection: kTargetPropertiesSectionIndex, tableView: tableView)
    csPropertiesSection = CommonSchemaPropertiesTableSection(tableSection: kCSPropertiesSectionIndex, tableView: tableView)
    
    // Default target section.
    let defaultTargetSection = MSTransmissionTargetSection()
    defaultTargetSection.headerText = "Default Transmission Target"
    defaultTargetSection.footerText = "Changing this target's enabled state will not take effect until the app is restarted. While the default target is enabled, all services other than Analytics will be unusable."
    defaultTargetSection.isDefault = true

    // Runtime target section.
    let runtimeTargetSection = MSTransmissionTargetSection()
    runtimeTargetSection.headerText = "Runtime Transmission Target"
    runtimeTargetSection.footerText = "This transmission target is the parent of the two transmission targets below."
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    let objCRuntimeToken = kMSPuppetRuntimeTargetToken
    #else
    let objCRuntimeToken = kMSObjCRuntimeTargetToken
    #endif
    runtimeTargetSection.token = appName == "SasquatchSwift" ? kMSSwiftRuntimeTargetToken : objCRuntimeToken

    // Child 1.
    let child1TargetSection = MSTransmissionTargetSection()
    child1TargetSection.headerText = "Child Transmission Target 1"
    child1TargetSection.token = kMSTargetToken1

    // Child 2.
    let child2TargetSection = MSTransmissionTargetSection()
    child2TargetSection.headerText = "Child Transmission Target 2"
    child2TargetSection.token = kMSTargetToken2

    // The ordering of these target sections is important so they are displayed in the right order.
    transmissionTargetSections = [defaultTargetSection, runtimeTargetSection, child1TargetSection, child2TargetSection]
    tableView.setEditing(true, animated: false)
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return transmissionTargetSections!.count + 2
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == kTargetPropertiesSectionIndex {
      return targetPropertiesSection!.tableView(tableView, numberOfRowsInSection:section)
    }
    else if section == kCSPropertiesSectionIndex {
      return 4
    }
    else {
      return 3
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == kTargetPropertiesSectionIndex {
      return targetPropertiesSection!.tableView(tableView, cellForRowAt:indexPath)
    }
    else if indexPath.section == kCSPropertiesSectionIndex {
      return csPropertiesSection!.tableView(tableView, cellForRowAt: indexPath)
    }
    let section = transmissionTargetSections![indexPath.section]
    switch indexPath.row {
    case kEnabledCellRowIndex:
      let cell = tableView.dequeueReusableCell(withIdentifier: kEnabledSwitchCellId)!
      let switcher: UISwitch? = getSubviewFromCell(cell)
      switcher?.isOn = section.isTransmissionTargetEnabled()
      switcher?.addTarget(self, action: #selector(targetEnabledSwitchValueChanged), for: .valueChanged)

      // Special label text for default target section.
      if indexPath.section == kDefaultTargetSectionIndex {
        let label: UILabel? = getSubviewFromCell(cell)
        label!.text = "Enabled Next Launch"
      }
      return cell
    case kAnalyticsCellRowIndex:
      let cell = tableView.dequeueReusableCell(withIdentifier: kAnalyticsSwitchCellId)!
      let switcher: UISwitch? = getSubviewFromCell(cell)
      switcher?.isOn = section.shouldSendAnalytics()
      switcher?.addTarget(self, action: #selector(targetShouldSendAnalyticsSwitchValueChanged), for: .valueChanged)
      return cell
    case kTokenCellRowIndex:
      if indexPath.section == kDefaultTargetSectionIndex {
        fallthrough
      }
      let cell = tableView.dequeueReusableCell(withIdentifier: kTokenCellId)!
      let label: UILabel? = getSubviewFromCell(cell, withTag:kTokenDisplayLabelTag)
      label?.text = section.token
      return cell
    case kEnabledStateIndicatorRowIndex:
      let cell = tableView.dequeueReusableCell(withIdentifier: kEnabledStateIndicatorCellId)!
      cell.detailTextLabel!.text = MSTransmissionTargetsViewController.defaultTransmissionTargetIsEnabled ? "Enabled" : "Disabled"
      return cell
    default:
      return super.tableView(tableView, cellForRowAt: indexPath)
    }
  }

  func targetEnabledSwitchValueChanged(sender: UISwitch!) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    section.setTransmissionTargetEnabled(sender!.isOn)
    if (sectionIndex == 1) {
      for childSectionIndex in 2...3 {
        guard let childCell = tableView.cellForRow(at: IndexPath(row: kEnabledCellRowIndex, section: childSectionIndex)) else {
          continue
        }
        let childSwitch: UISwitch? = getSubviewFromCell(childCell)
        let childTarget = transmissionTargetSections![childSectionIndex].getTransmissionTarget()
        childSwitch!.setOn(childTarget!.isEnabled(), animated: true)
        childSwitch?.isEnabled = sender!.isOn
      }
    }
  }

  func targetShouldSendAnalyticsSwitchValueChanged(sender: UISwitch!) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    section.setShouldSendAnalytics(enabledState: sender!.isOn)
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section < transmissionTargetSections!.count {
      return transmissionTargetSections![section].headerText
    }
    else if section == kCSPropertiesSectionIndex {
      return "Override Common Schema Properties"
    }

    return "Transmission Target Properties"
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    if section < transmissionTargetSections!.count {
      return transmissionTargetSections![section].footerText
    }
    return nil
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if indexPath.section == kTargetPropertiesSectionIndex {
      targetPropertiesSection?.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
    }
  }

  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if indexPath.section == kTargetPropertiesSectionIndex {
      return targetPropertiesSection!.tableView(tableView, editingStyleForRowAt: indexPath)
    }
    return .none
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if indexPath.section == kTargetPropertiesSectionIndex && targetPropertiesSection!.isInsertRow(indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == kTargetPropertiesSectionIndex || indexPath.section == kCSPropertiesSectionIndex {
      return super.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: indexPath.section))
    }
    return super.tableView(tableView, heightForRowAt: indexPath)
  }

  /**
   * Without this override, the default implementation will try to get a table cell that is out of bounds
   * (since they are inserted/removed at a slightly different time than the actual data source is updated).
   */
  override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
    return 0
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if indexPath.section == kTargetPropertiesSectionIndex {
      return targetPropertiesSection!.tableView(tableView, canEditRowAt:indexPath)
    }
    return false
  }

  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return false
  }

  private func getSubviewFromCell<T: UIView>(_ cell: UITableViewCell, withTag tag:Int = 0) -> T? {
    for subview in cell.contentView.subviews {
      if  (subview.tag == tag) && (subview is T) {
        return subview as? T
      }
    }
    return nil
  }

  private func getCellSection(forView view: UIView) -> Int {
    let cell = view.superview!.superview as! UITableViewCell
    let indexPath = tableView.indexPath(for: cell)!
    return indexPath.section
  }
}
