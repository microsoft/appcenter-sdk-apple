import UIKit

class EventPropertiesTableSection : TypedPropertiesTableSection {

  private var propertiesCount = 0

  override func getPropertyCount() -> Int {
    return propertiesCount
  }

  override func addProperty() {
    propertiesCount += 1
  }

  override func removeProperty(atRow row: Int) {
    propertiesCount -= 1
  }

  func eventProperties() -> Any? {
    if propertiesCount < 1 {
      return nil
    }
    var onlyStrings = true
    var propertyDictionary = [String: String]()
    let eventProperties = MSEventProperties()
    for i in 1...propertiesCount {
      let indexPath = IndexPath(row: i, section: self.tableSection)
      if let cell = self.tableView.cellForRow(at: indexPath) as? MSAnalyticsTypedPropertyTableViewCell {
        cell.setPropertyTo(eventProperties)
        if cell.type == .String {
          let key = cell.keyTextField.text
          propertyDictionary[key!] = cell.valueTextField.text
        } else {
          onlyStrings = false
        }
      }
    }
    return onlyStrings ? propertyDictionary : eventProperties
  }
}

