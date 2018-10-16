import UIKit

class TargetPropertiesTableSection : PropertiesTableSection {
  typealias EventPropertyType = MSAnalyticsTypedPropertyTableViewCell.EventPropertyType
  typealias PropertyState = MSAnalyticsTypedPropertyTableViewCell.PropertyState

  private var targetProperties = [String: [PropertyState]]()
  private var transmissionTargetSelectorCell: MSAnalyticsTransmissionTargetSelectorViewCell?

  override init(tableSection: Int, tableView: UITableView) {
    super.init(tableSection: tableSection, tableView: tableView)
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    let parentTargetToken = appName.contains("SasquatchSwift") ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken
    targetProperties[parentTargetToken] = [PropertyState]()
    targetProperties[kMSTargetToken1] = [PropertyState]()
    targetProperties[kMSTargetToken2] = [PropertyState]()
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

  override func loadCell(row: Int) -> UITableViewCell {
    guard let cell: MSAnalyticsTypedPropertyTableViewCell = loadCellFromNib() else {
      preconditionFailure("Cannot load table view cell")
    }
    let arrayIndex = row - self.propertyCellOffset
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    cell.state = targetProperties[selectedTarget!]![arrayIndex]
    cell.onChange = { state in
      let key = self.targetProperties[selectedTarget!]![arrayIndex].key
      self.targetProperties[selectedTarget!]![arrayIndex] = state
      target.propertyConfigurator.removeEventProperty(forKey: key)
      self.setEventPropertyState(state, forTarget: target)
    }
    return cell
  }

  override func getPropertyCount() -> Int {
    let selectedTarget = transmissionTargetSelectorCell!.selectedTransmissionTarget()
    return (targetProperties[selectedTarget!]!.count)
  }

  override func addProperty() {
    let count = getPropertyCount()
    let state: PropertyState = ("key\(count)", EventPropertyType.String, "value\(count)")
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    targetProperties[selectedTarget!]!.insert(state, at: 0)
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    setEventPropertyState(state, forTarget: target)
  }

  override func removeProperty(atRow row: Int) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let arrayIndex = row - self.propertyCellOffset
    let key = targetProperties[selectedTarget!]![arrayIndex].key
    let target = MSTransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.removeEventProperty(forKey: key)
    targetProperties[selectedTarget!]!.remove(at: arrayIndex)
  }

  func setEventPropertyState(_ state: PropertyState, forTarget target: MSAnalyticsTransmissionTarget) {

    // TODO Add missing cases once new APIs available
    switch state.type {
    case .String:
      target.propertyConfigurator.setEventPropertyString(state.value as! String, forKey: state.key)
    default:
      NSLog("There is no API for event property with type \"\(state.type)\"")
    }
  }

  func isHeaderCell(_ indexPath: IndexPath) -> Bool {
    return !(isPropertyRow(indexPath) || isInsertRow(indexPath))
  }
}
