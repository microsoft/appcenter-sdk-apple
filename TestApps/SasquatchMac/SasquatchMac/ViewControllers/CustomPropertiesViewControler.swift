import Cocoa

class CustomProperty : NSObject {
  var key: String? = nil
  var type: String = "Clear"
  var value: Any? = nil
}

class CustomPropertiesViewControler: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSComboBoxDelegate {

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
    cell.isHidden = false
    switch property.type {
    case "String": ()
    case "Number": ()
    case "Boolean": ()
    case "DateTime": ()
    default:
      cell.isHidden = true
    }
  }
}
