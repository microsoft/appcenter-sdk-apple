import UIKit

class TypedPropertiesTableSection : PropertiesTableSection {
  typealias EventPropertyType = MSAnalyticsTypedPropertyTableViewCell.EventPropertyType

  var typedProperties = [(key: String, type: EventPropertyType, value: Any)]()

  override func loadCell(row: Int) -> UITableViewCell {
    guard let cell: MSAnalyticsTypedPropertyTableViewCell = loadCellFromNib() else {
      preconditionFailure("Cannot load table view cell")
    }

    // Set cell text.
    cell.state = typedProperties[row - self.propertyCellOffset]
    cell.onChange = { state in
      self.typedProperties[row - self.propertyCellOffset] = state
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
}
