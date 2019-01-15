import UIKit

class SimplePropertiesTableSection : PropertiesTableSection {

  override func loadCell(row: Int) -> UITableViewCell {
    guard let cell: MSAnalyticsPropertyTableViewCell = loadCellFromNib() else {
      preconditionFailure("Cannot load table view cell")
    }

    // Set cell text.
    let property = propertyAtRow(row: row)
    cell.keyField.text = property.key
    cell.valueField.text = property.value
    cell.tag = row

    // Set cell to respond to being edited.
    cell.keyField.addTarget(self, action: #selector(propertyKeyChanged), for: .editingDidEnd)
    cell.valueField.addTarget(self, action: #selector(propertyValueChanged), for: .editingDidEnd)

    return cell
  }

  override func addProperty() {
    let count = getPropertyCount()
    addProperty(property: ("key\(count)", "value\(count)"))
  }

  func addProperty(property: (key: String, value: String)) {
    preconditionFailure("This method is abstract")
  }

  func propertyAtRow(row: Int) -> (key: String, value: String) {
    preconditionFailure("This method is abstract")
  }

  func propertyKeyChanged(sender: UITextField!) {
    preconditionFailure("This method is abstract")
  }

  func propertyValueChanged(sender: UITextField!) {
    preconditionFailure("This method is abstract")
  }

  func getCellRow(forTextField textField: UITextField!) -> Int {
    let cell = textField.superview!.superview as! UITableViewCell
    return cell.tag
  }
}
