import UIKit

class TargetPropertiesTableSection : PropertiesTableSection {

  var targetProperties: [String: [(String, String)]]!
  var transmissionTargetSelectorCell: MSAnalyticsTranmissionTargetSelectorViewCell?
  var transmissionTargets: [String: MSAnalyticsTransmissionTarget]!

  override init(tableSection: Int, tableView: UITableView) {
    super.init(tableSection: tableSection, tableView: tableView)
    // Set up all transmission targets and associated mappings. The three targets and their tokens are hard coded.
    transmissionTargets = [String: MSAnalyticsTransmissionTarget]()
    targetProperties = [String: [(String, String)]]()
 
    // Parent target.
    let parentTargetToken = TargetPropertiesTableSection.parentTransmissionTargetToken()
    let parentTarget = MSAnalytics.transmissionTarget(forToken: parentTargetToken)
    transmissionTargets[parentTargetToken] = parentTarget
    targetProperties[parentTargetToken] = [(String, String)]()

    // Child 1 target.
    let childTarget1 = parentTarget.transmissionTarget(forToken: kMSTargetToken1)
    transmissionTargets[kMSTargetToken1] = childTarget1
    targetProperties[kMSTargetToken1] = [(String, String)]()

    // Child 2 target.
    let childTarget2 = parentTarget
      .transmissionTarget(forToken: kMSTargetToken2)
    transmissionTargets[kMSTargetToken2] = childTarget2
    targetProperties[kMSTargetToken2] = [(String, String)]()
    transmissionTargetSelectorCell = loadCellFromNib()
    transmissionTargetSelectorCell?.didSelectTransmissionTarget = tableView.reloadData
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
    let target = transmissionTargets![selectedTarget!]
    target!.removeEventPropertyforKey(currentPropertyKey)
    target!.setEventPropertyString(currentPropertyValue, forKey: sender.text!)
    targetProperties[selectedTarget!]![arrayIndex].0 = sender.text!
  }

  override func propertyValueChanged(sender: UITextField!) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let arrayIndex = getCellRow(forTextField: sender) - propertyCellOffset()
    let currentPropertyKey = targetProperties[selectedTarget!]![arrayIndex].0
    let target = transmissionTargets![selectedTarget!]
    target?.setEventPropertyString(sender.text!, forKey: currentPropertyKey)
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
    let target = transmissionTargets![selectedTarget!]
    target!.removeEventPropertyforKey(key)
    targetProperties[selectedTarget!]!.remove(at: arrayIndex)
  }

  override func addProperty(property: (String, String)) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    targetProperties[selectedTarget!]!.insert(property, at: 0)
    let target = transmissionTargets![selectedTarget!]
    target!.setEventPropertyString(property.1, forKey: property.0)
  }

  func isHeaderCell(_ indexPath: IndexPath) -> Bool {
    return !(isPropertyRow(indexPath) || isInsertRow(indexPath))
  }

  func transmissionTarget(forTargetToken token: String) -> MSAnalyticsTransmissionTarget {
    return transmissionTargets[token]!
  }
  
 public class func parentTransmissionTargetToken() -> String {
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    return appName == "SasquatchSwift" ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken
  }
}

