import UIKit

class TargetPropertiesTableSection : SimplePropertiesTableSection {
  private var targetProperties = [String: [(key: String, value: String)]]()
  private var transmissionTargetSelectorCell: MSAnalyticsTransmissionTargetSelectorViewCell?

  override init(tableSection: Int, tableView: UITableView) {
    super.init(tableSection: tableSection, tableView: tableView)
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    let parentTargetToken = appName.contains("SasquatchSwift") ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken
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

  override var numberOfCustomHeaderCells: Int {
    get { return 1 }
  }

  override func propertyKeyChanged(sender: UITextField!) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let arrayIndex = getCellRow(forTextField: sender) - self.propertyCellOffset
    let currentPropertyKey = targetProperties[selectedTarget!]![arrayIndex].key
    let currentPropertyValue = targetProperties[selectedTarget!]![arrayIndex].value
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.removeEventProperty(forKey: currentPropertyKey)
    target.propertyConfigurator.setEventPropertyString(currentPropertyValue, forKey: sender.text!)
    targetProperties[selectedTarget!]![arrayIndex].key = sender.text!
  }

  override func propertyValueChanged(sender: UITextField!) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let arrayIndex = getCellRow(forTextField: sender) - self.propertyCellOffset
    let currentPropertyKey = targetProperties[selectedTarget!]![arrayIndex].key
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.setEventPropertyString(sender.text!, forKey: currentPropertyKey)
    targetProperties[selectedTarget!]![arrayIndex].value = sender.text!
  }

  override func propertyAtRow(row: Int) -> (key: String, value: String) {
    let selectedTarget = transmissionTargetSelectorCell!.selectedTransmissionTarget()
    return targetProperties[selectedTarget!]![row - self.propertyCellOffset]
  }

  override func getPropertyCount() -> Int {
    let selectedTarget = transmissionTargetSelectorCell!.selectedTransmissionTarget()
    return (targetProperties[selectedTarget!]!.count)
  }

  override func removeProperty(atRow row: Int) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let arrayIndex = row - self.propertyCellOffset
    let key = targetProperties[selectedTarget!]![arrayIndex].key
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.removeEventProperty(forKey: key)
    targetProperties[selectedTarget!]!.remove(at: arrayIndex)
  }

  override func addProperty(property: (key: String, value: String)) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    targetProperties[selectedTarget!]!.insert(property, at: 0)
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.setEventPropertyString(property.value, forKey: property.key)
  }

  func isHeaderCell(_ indexPath: IndexPath) -> Bool {
    return !(isPropertyRow(indexPath) || isInsertRow(indexPath))
  }
}
