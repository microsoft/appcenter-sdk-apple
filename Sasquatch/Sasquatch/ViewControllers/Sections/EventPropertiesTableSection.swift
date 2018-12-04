import UIKit

class EventPropertiesTableSection : PropertiesTableSection {
  typealias EventPropertyType = MSAnalyticsTypedPropertyTableViewCell.EventPropertyType
  typealias PropertyState = MSAnalyticsTypedPropertyTableViewCell.PropertyState

  private var typedProperties = [PropertyState]()

  override func loadCell(row: Int) -> UITableViewCell {
    guard let cell: MSAnalyticsTypedPropertyTableViewCell = loadCellFromNib() else {
      preconditionFailure("Cannot load table view cell")
    }
    cell.state = typedProperties[row - self.propertyCellOffset]
    cell.onChange = { state in
      let cellRow = self.tableView.indexPath(for: cell)!.row;
      self.typedProperties[cellRow - self.propertyCellOffset] = state
    }
    return cell
  }

  override func getPropertyCount() -> Int {
    return typedProperties.count
  }

  override func addProperty() {
    let count = getPropertyCount()
    typedProperties.insert(("key\(count)", EventPropertyType.String, "value\(count)"), at: 0)
  }

  override func removeProperty(atRow row: Int) {
    typedProperties.remove(at: row - self.propertyCellOffset)
  }

  func eventProperties() -> Any? {
    if typedProperties.count < 1 {
      return nil
    }
    var onlyStrings = true
    var propertyDictionary = [String: String]()
    let eventProperties = MSEventProperties()
    for property in typedProperties {
      switch property.type {
      case .String:
        eventProperties.setEventProperty(property.value as! String, forKey: property.key);
        propertyDictionary[property.key] = (property.value as! String)
      case .Double:
        eventProperties.setEventProperty(property.value as! Double, forKey: property.key)
        onlyStrings = false
      case .Long:
        eventProperties.setEventProperty(property.value as! Int64, forKey: property.key)
        onlyStrings = false
      case .Boolean:
        eventProperties.setEventProperty(property.value as! Bool, forKey: property.key)
        onlyStrings = false
      case .DateTime:
        eventProperties.setEventProperty(property.value as! Date, forKey: property.key)
        onlyStrings = false
      }
    }
    return onlyStrings ? propertyDictionary : eventProperties
  }
}

