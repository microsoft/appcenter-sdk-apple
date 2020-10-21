// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class CommonSchemaPropertiesTableSection : SimplePropertiesTableSection {

  let kTargetSelectorCellRow = 0
  let kDeviceIdRow = 1
  let kNumberOfHeaderCells = 2
  let switchCellIdentifier = "collectdeviceidswitchcell"
  let propertyKeys = ["App Name", "App Version", "App Locale", "User Id"]
  var propertyValues: [String: [String]]!
  var transmissionTargetSelectorCell: MSAnalyticsTransmissionTargetSelectorViewCell?
  var collectDeviceIdStates: [String: Bool]!
  
  enum CommonSchemaPropertyRow : Int {
    case AppName = 0
    case AppVersion
    case AppLocale
    case UserId
  }

  override var numberOfCustomHeaderCells: Int {
    get { return kNumberOfHeaderCells }
  }

  // Since properties are static, there is no "insert" row.
  override var hasInsertRow: Bool {
    get { return false }
  }

  override init(tableSection: Int, tableView: UITableView) {
    super.init(tableSection: tableSection, tableView: tableView)
    propertyValues = [String: [String]]()
    collectDeviceIdStates = [String: Bool]()
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    let parentTargetToken = appName.contains("SasquatchSwift") ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken
    for token in [parentTargetToken, kMSTargetToken1, kMSTargetToken2] {
      propertyValues[token] = Array(repeating: "", count: propertyKeys.count + 1)
      collectDeviceIdStates[token] = false
    }
    transmissionTargetSelectorCell = loadCellFromNib()
    transmissionTargetSelectorCell?.didSelectTransmissionTarget = reloadSection
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch indexPath.row {
    case kTargetSelectorCellRow:
      return transmissionTargetSelectorCell!
    case kDeviceIdRow:
      let cell = tableView.dequeueReusableCell(withIdentifier: switchCellIdentifier)!
      let switcher: UISwitch? = cell.getSubview()
      let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()!
      switcher!.isOn = collectDeviceIdStates[selectedTarget!]!
      switcher!.isEnabled = !switcher!.isOn
      switcher!.addTarget(self, action: #selector(collectDeviceIdSwitchCellEnabled(sender:)), for: .valueChanged)
      return cell
    default:
      let cell = super.tableView(tableView, cellForRowAt: indexPath) as! MSAnalyticsPropertyTableViewCell
      cell.valueField.placeholder = "Override value"
      return cell
    }
  }

  // Note down current target for using in End edit events.
  override func recordCurrentTarget(sender: UITextField!) {
    let Cell = sender.superview!.superview as! MSAnalyticsPropertyTableViewCell
    Cell.currentTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget() ?? ""
  }

  // Add below method since tap out of the key textField will crash the app, that's a bad experience.
  override func propertyKeyChanged(sender: UITextField!) {    
  }

  override func propertyValueChanged(sender: UITextField!) {

    // Check out whether the target have been changed, if so, change to use original target.
    let Cell = sender.superview!.superview as! MSAnalyticsPropertyTableViewCell
    let currentTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let selectedTarget = Cell.currentTarget != currentTarget ? Cell.currentTarget : currentTarget
    
    let propertyIndex = getCellRow(forTextField: sender) - self.propertyCellOffset
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    propertyValues[selectedTarget!]![propertyIndex] = sender.text!
    switch CommonSchemaPropertyRow(rawValue: propertyIndex)! {
    case .AppName:
      target.propertyConfigurator.appName = sender.text!
      break
    case .AppVersion:
      target.propertyConfigurator.appVersion = sender.text!
      break
    case .AppLocale:
      target.propertyConfigurator.appLocale = sender.text!
      break
    case .UserId:
      let text = sender.text ?? ""
      let userId = !text.isEmpty ? text : nil
      target.propertyConfigurator.userId = userId
      break
    }
    sender.resignFirstResponder()
  }

  override func propertyAtRow(row: Int) -> (String, String) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let propertyIndex = row - self.propertyCellOffset
    let value = propertyValues[selectedTarget!]![propertyIndex]
    return (propertyKeys[row - numberOfCustomHeaderCells], value)
  }

  override func getPropertyCount() -> Int {
    return propertyKeys.count
  }

  @objc func collectDeviceIdSwitchCellEnabled(sender: UISwitch?) {

    /*
     * Disable the switch. This results in the switch's color being muted to
     * indicate that the switch is disabled. This is okay in this case.
     */
    sender!.isEnabled = false

    // Update the transmission target.
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.collectDeviceId()

    // Update in memory state for display.
    collectDeviceIdStates[selectedTarget!] = true
  }
}
