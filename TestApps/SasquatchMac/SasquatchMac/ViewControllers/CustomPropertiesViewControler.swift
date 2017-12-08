import Cocoa
import AppCenter

class CustomPropertiesViewControler: NSViewController {
  
  enum CustomPropertyType : String {
    case Clear = "Clear"
    case String = "String"
    case Number = "Number"
    case Boolean = "Boolean"
    case DateTime = "DateTime"
    
     static let allValues = [Clear, String, Number, Boolean, DateTime]
  }
  
  class CustomProperty : NSObject {
    var key: String? = nil
    var type: String = CustomPropertyType.Clear.rawValue
    var string: String? = nil
    var number: NSNumber? = nil
    var boolean: Bool = false
    var dateTime: Date? = nil
  }
  
  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!
  
  @IBOutlet var arrayController: NSArrayController!
  @IBOutlet weak var tableView: NSTableView!
  dynamic var properties = [CustomProperty]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  @IBAction func addProperty(_ sender: Any) {
    let property = CustomProperty()
    property.addObserver(self, forKeyPath: #keyPath(CustomProperty.type), options: .new, context: nil)
    arrayController.addObject(property)
  }
  
  @IBAction func deleteProperty(_ sender: Any) {
    if let selectedProperty = arrayController.selectedObjects.first as? CustomProperty {
      arrayController.removeObject(selectedProperty)
    }
  }
  
  @IBAction func send(_ sender: Any) {
    let customProperties = MSCustomProperties()
    for property in properties {
      guard let key = property.key else {
        continue
      }
      guard let type = CustomPropertyType(rawValue: property.type) else {
        continue
      }
      switch type {
      case .Clear:
        customProperties.clearProperty(forKey: key)
      case .String:
        if let value = property.string {
          customProperties.setString(value, forKey: key)
        }
      case .Number:
        if let value = property.number {
          customProperties.setNumber(value, forKey: key)
        }
      case .Boolean:
        let value = property.boolean
        customProperties.setBool(value, forKey: key)
      case .DateTime:
        if let value = property.dateTime {
          customProperties.setDate(value, forKey: key)
        }
      }
    }
    appCenter.setCustomProperties(customProperties)
    print("send")
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard let property = object as? CustomProperty else {
      return
    }
    guard let row = properties.index(of: property) else {
      return
    }
    let column = tableView.column(withIdentifier: "value")
    guard let cell = tableView.view(atColumn: column, row: row, makeIfNecessary: false) as? NSTableCellView else {
      return
    }
    updateValue(property: property, cell: cell)
  }
  
  func updateValue(property: CustomProperty, cell: NSTableCellView) {
    cell.isHidden = false
    for subview in cell.subviews {
      subview.isHidden = true
    }
    guard let type = CustomPropertyType(rawValue: property.type) else {
      return
    }
    if let view = cell.viewWithTag(CustomPropertyType.allValues.index(of: type)!) {
      view.isHidden = false
    } else {
      cell.isHidden = true
    }
  }
}
