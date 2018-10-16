import UIKit

class MSTransmissionTargetsViewController: UITableViewController, AppCenterProtocol {
  var appCenter: AppCenterDelegate!

  private class MSTransmissionTargetSection: NSObject {
    static var defaultTransmissionTargetIsEnabled: Bool?
    
    var token: String?
    var headerText: String?
    var footerText: String?
    var isDefault = false

    func isTransmissionTargetEnabled() -> Bool {
      if isDefault {
        return MSTransmissionTargets.shared.defaultTransmissionTargetIsEnabled
      } else {
        return getTransmissionTarget()!.isEnabled()
      }
    }

    func setTransmissionTargetEnabled(_ enabledState: Bool) {
      if !isDefault {
        getTransmissionTarget()!.setEnabled(enabledState)
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

    func pause() {
      getTransmissionTarget()!.pause()
    }

    func resume() {
      getTransmissionTarget()!.resume()
    }
  }

  private var transmissionTargetSections: [MSTransmissionTargetSection]?
  private let kEnabledSwitchCellId = "enabledswitchcell"
  private let kAnalyticsSwitchCellId = "analyticsswitchcell"
  private let kTokenCellId = "tokencell"
  private let kPauseCellId = "pausecell"
  private let kEnabledStateIndicatorCellId = "enabledstateindicator"
  private let kTokenDisplayLabelTag = 1
  private let kEnabledCellRowIndex = 0
  private let kAnalyticsCellRowIndex = 1
  private let kTokenCellRowIndex = 2
  private let kPauseCellRowIndex = 3
  private var targetPropertiesSection: TargetPropertiesTableSection?
  private var csPropertiesSection: CommonSchemaPropertiesTableSection?
  
  enum Section : Int {
    case Default = 0
    case Runtime
    case Child1
    case Child2
    case TargetProperties
    case CommonSchemaProperties
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    targetPropertiesSection = TargetPropertiesTableSection(tableSection: Section.TargetProperties.rawValue, tableView: tableView)
    csPropertiesSection = CommonSchemaPropertiesTableSection(tableSection: Section.CommonSchemaProperties.rawValue, tableView: tableView)
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String

    // Test start from library.
    appCenter.startAnalyticsFromLibrary()

    // Default target section.
    let defaultTargetSection = MSTransmissionTargetSection()
    defaultTargetSection.headerText = "Default Transmission Target"
    defaultTargetSection.footerText = "You need to change startup mode and restart the app to get update this target's enabled state."
    defaultTargetSection.isDefault = true
    defaultTargetSection.token = appName.contains("SasquatchSwift") ? kMSSwiftTargetToken : kMSObjCTargetToken

    // Runtime target section.
    let runtimeTargetSection = MSTransmissionTargetSection()
    runtimeTargetSection.headerText = "Runtime Transmission Target"
    runtimeTargetSection.footerText = "This transmission target is the parent of the two transmission targets below."
    runtimeTargetSection.token = appName.contains("SasquatchSwift") ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken

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
    tableView.estimatedRowHeight = tableView.rowHeight
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.setEditing(true, animated: false)
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return transmissionTargetSections!.count + 2
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == Section.TargetProperties.rawValue {
      return targetPropertiesSection!.tableView(tableView, numberOfRowsInSection:section)
    }
    else if section == Section.CommonSchemaProperties.rawValue {
      return csPropertiesSection!.tableView(tableView, numberOfRowsInSection:section)
    }
    else if section == Section.Default.rawValue {
      return 3
    }
    else {
      return 4
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == Section.TargetProperties.rawValue {
      return targetPropertiesSection!.tableView(tableView, cellForRowAt:indexPath)
    }
    else if indexPath.section == Section.CommonSchemaProperties.rawValue {
      return csPropertiesSection!.tableView(tableView, cellForRowAt: indexPath)
    }
    let section = transmissionTargetSections![indexPath.section]
    switch indexPath.row {
    case kEnabledCellRowIndex:
      let cell = tableView.dequeueReusableCell(withIdentifier: kEnabledSwitchCellId)!
      let switcher: UISwitch? = cell.getSubview()
      switcher?.isOn = section.isTransmissionTargetEnabled()
      switcher?.isEnabled = indexPath.section != Section.Default.rawValue
      switcher?.addTarget(self, action: #selector(targetEnabledSwitchValueChanged), for: .valueChanged)
      let label: UILabel? = cell.getSubview()
      label!.text = "Set Enabled"
      return cell
    case kAnalyticsCellRowIndex:
      let cell = tableView.dequeueReusableCell(withIdentifier: kAnalyticsSwitchCellId)!
      let switcher: UISwitch? = cell.getSubview()
      switcher?.isOn = section.shouldSendAnalytics()
      switcher?.addTarget(self, action: #selector(targetShouldSendAnalyticsSwitchValueChanged), for: .valueChanged)
      return cell
    case kTokenCellRowIndex:
      let cell = tableView.dequeueReusableCell(withIdentifier: kTokenCellId)!
      let label: UILabel? = cell.getSubview(withTag: kTokenDisplayLabelTag)
      label?.text = section.token
      return cell
    case kPauseCellRowIndex:
      return tableView.dequeueReusableCell(withIdentifier: kPauseCellId)!
    default:
      return super.tableView(tableView, cellForRowAt: indexPath)
    }
  }

  func targetEnabledSwitchValueChanged(sender: UISwitch!) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    if (sectionIndex == Section.Default.rawValue) {
      section.setTransmissionTargetEnabled(sender!.isOn)
    }
    else if sectionIndex == Section.Runtime.rawValue {
      section.setTransmissionTargetEnabled(sender!.isOn)
      for childSectionIndex in 2...3 {
        guard let childCell = tableView.cellForRow(at: IndexPath(row: kEnabledCellRowIndex, section: childSectionIndex)) else {
          continue
        }
        let childSwitch: UISwitch? = childCell.getSubview()
        let childTarget = transmissionTargetSections![childSectionIndex].getTransmissionTarget()
        childSwitch!.setOn(childTarget!.isEnabled(), animated: true)
        childSwitch!.isEnabled = sender!.isOn
      }
    }
    else if sectionIndex == Section.Child1.rawValue || sectionIndex == Section.Child2.rawValue {
      let switchEnabled = sender!.isOn
      section.setTransmissionTargetEnabled(switchEnabled)
      if switchEnabled && !section.isTransmissionTargetEnabled() {
        
        // Switch tried to enable the transmission target but it didn't work.
        sender!.setOn(false, animated: true)
        section.setTransmissionTargetEnabled(false)
        sender!.isEnabled = false
      }
    }
  }

  func targetShouldSendAnalyticsSwitchValueChanged(sender: UISwitch!) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    section.setShouldSendAnalytics(enabledState: sender!.isOn)
  }

  @IBAction func pause(_ sender: UIButton) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    section.pause()
  }

  @IBAction func resume(_ sender: UIButton) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    section.resume()
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section < transmissionTargetSections!.count {
      return transmissionTargetSections![section].headerText
    }
    else if section == Section.CommonSchemaProperties.rawValue {
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
    if indexPath.section == Section.TargetProperties.rawValue {
      targetPropertiesSection?.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
    }
  }

  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if indexPath.section == Section.TargetProperties.rawValue {
      return targetPropertiesSection!.tableView(tableView, editingStyleForRowAt: indexPath)
    }
    return .none
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if indexPath.section == Section.TargetProperties.rawValue && targetPropertiesSection!.isInsertRow(indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }

  /*
   * Without this override, the default implementation will try to get a table cell that is out of bounds
   * (since they are inserted/removed at a slightly different time than the actual data source is updated).
   */
  override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
    return 0
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if indexPath.section == Section.TargetProperties.rawValue {
      return targetPropertiesSection!.tableView(tableView, canEditRowAt:indexPath)
    }
    return false
  }

  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return false
  }

  private func getCellSection(forView view: UIView) -> Int {
    let cell = view.superview!.superview as! UITableViewCell
    let indexPath = tableView.indexPath(for: cell)!
    return indexPath.section
  }
}
