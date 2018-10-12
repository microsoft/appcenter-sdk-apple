import UIKit

class EventPropertiesTableSection : TypedPropertiesTableSection {

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
        eventProperties.setString(property.value as! String, forKey:property.key)
        propertyDictionary[property.key] = (property.value as! String)
        break
      case .Double:
        eventProperties.setDouble(property.value as! Double, forKey:property.key)
        onlyStrings = false
        break
      case .Long:
        eventProperties.setInt64(property.value as! Int64, forKey:property.key)
        onlyStrings = false
        break
      case .Boolean:
        eventProperties.setBool(property.value as! Bool, forKey:property.key)
        onlyStrings = false
        break
      case .DateTime:
        eventProperties.setDate(property.value as! Date, forKey:property.key)
        onlyStrings = false
        break
      }
    }
    return onlyStrings ? propertyDictionary : eventProperties
  }
}

