import UIKit

class TargetPropertiesTableSection : PropertiesTableSection {
  var targetProperties: [String: [(String, String)]]!
  var transmissionTargetSelectorCell: MSAnalyticsTransmissionTargetSelectorViewCell?

  override init(tableSection: Int, tableView: UITableView) {
    super.init(tableSection: tableSection, tableView: tableView)
    targetProperties = [String: [(String, String)]]()
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    let objCRuntimeToken = kMSPuppetRuntimeTargetToken
    #else
    let objCRuntimeToken = kMSObjCRuntimeTargetToken
    #endif
    let parentTargetToken = appName == "SasquatchSwift" ? kMSSwiftRuntimeTargetToken : objCRuntimeToken
    targetProperties[parentTargetToken] = [(String, String)]()
    targetProperties[kMSTargetToken1] = [(String, String)]()
    targetProperties[kMSTargetToken2] = [(String, String)]()
    transmissionTargetSelectorCell = loadCellFromNib()
    transmissionTargetSelectorCell?.didSelectTransmissionTarget = reloadSection
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if isHeaderCell(indexPath) {
      return transmissionTargetSelectorCell!
    } else {
      return super.tableView(tableView, cellForRowAt: indexPath)
    }
  }

  override func numberOfCustomHeaderCells() -> Int {
    return 1
  }

  override func propertyKeyChanged(sender: UITextField!) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let arrayIndex = getCellRow(forTextField: sender) - propertyCellOffset()
    let currentPropertyKey = targetProperties[selectedTarget!]![arrayIndex].0
    let currentPropertyValue = targetProperties[selectedTarget!]![arrayIndex].1
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.removeEventProperty(forKey: currentPropertyKey)
    target.propertyConfigurator.setEventPropertyString(currentPropertyValue, forKey: sender.text!)
    targetProperties[selectedTarget!]![arrayIndex].0 = sender.text!
  }

  override func propertyValueChanged(sender: UITextField!) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let arrayIndex = getCellRow(forTextField: sender) - propertyCellOffset()
    let currentPropertyKey = targetProperties[selectedTarget!]![arrayIndex].0
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.setEventPropertyString(sender.text!, forKey: currentPropertyKey)
    targetProperties[selectedTarget!]![arrayIndex].1 = sender.text!
  }

  override func propertyAtRow(row: Int) -> (String, String) {
    let selectedTarget = transmissionTargetSelectorCell!.selectedTransmissionTarget()
    return targetProperties[selectedTarget!]![row - propertyCellOffset()]
  }

  override func getPropertyCount() -> Int {
    let selectedTarget = transmissionTargetSelectorCell!.selectedTransmissionTarget()
    return (targetProperties[selectedTarget!]!.count)
  }

  override func removeProperty(atRow row: Int) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let arrayIndex = row - propertyCellOffset()
    let key = targetProperties[selectedTarget!]![arrayIndex].0
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.removeEventProperty(forKey: key)
    targetProperties[selectedTarget!]!.remove(at: arrayIndex)
  }

  override func addProperty(property: (String, String)) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    targetProperties[selectedTarget!]!.insert(property, at: 0)
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.setEventPropertyString(property.1, forKey: property.0)
  }

  func isHeaderCell(_ indexPath: IndexPath) -> Bool {
    return !(isPropertyRow(indexPath) || isInsertRow(indexPath))
  }
}
