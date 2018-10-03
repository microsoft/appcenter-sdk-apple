import UIKit

class EventPropertiesTableSection : TypedPropertiesTableSection {

  private var eventProperties: [(String, String)]! = [(String, String)]()

  override func getPropertyCount() -> Int {
    return eventProperties!.count
  }

  override func addProperty() {
    eventProperties!.insert(("", ""), at: 0)
  }

  override func removeProperty(atRow row: Int) {
    eventProperties!.remove(at: row - self.propertyCellOffset)
  }

  /*
  func eventPropertiesDictionary() -> [String: String] {
    var propertyDictionary = [String: String]()
    for pair in eventProperties {
      propertyDictionary[pair.0] = pair.1
    }
    return propertyDictionary
  }
 */
}

