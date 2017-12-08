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
    var value: Any? = nil
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
    property.value = nil
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
