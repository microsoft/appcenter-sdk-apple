import UIKit

class SimplePropertiesTableSection : PropertiesTableSection {
  
  static var propertyCounter = 0

  override func loadCell(row: Int) -> UITableViewCell {
    guard let cell: MSAnalyticsPropertyTableViewCell = loadCellFromNib() else {
      preconditionFailure("Cannot load table view cell")
    }

    // Set cell text.
    let property = propertyAtRow(row: row)
    cell.keyField.text = property.0
    cell.valueField.text = property.1

    // Set cell to respond to being edited.
    cell.keyField.addTarget(self, action: #selector(propertyKeyChanged), for: .editingChanged)
    cell.keyField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)
    cell.valueField.addTarget(self, action: #selector(propertyValueChanged), for: .editingChanged)
    cell.valueField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)

    return cell
  }

  override func addProperty() {
    addProperty(property: SimplePropertiesTableSection.getNewDefaultProperty())
  }

  func addProperty(property: (String, String)) {
    preconditionFailure("This method is abstract")
  }

  func propertyAtRow(row: Int) -> (String, String) {
    preconditionFailure("This method is abstract")
  }

  func propertyKeyChanged(sender: UITextField!) {
    preconditionFailure("This method is abstract")
  }

  func propertyValueChanged(sender: UITextField!) {
    preconditionFailure("This method is abstract")
  }

  func dismissKeyboard(sender: UITextField!) {
    sender.resignFirstResponder()
  }

  static func getNewDefaultProperty() -> (String, String) {
    let keyValuePair = ("key\(propertyCounter)", "value\(propertyCounter)")
    propertyCounter += 1
    return keyValuePair
  }
}
