import Cocoa

class CustomPropertiesViewControler: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

  @IBOutlet weak var tableView: NSTableView!
  var properties: [[String: Any]] = [
    ["key": "key1", "type": "Clear"],
    ["key": "key2", "type": "String", "value": "string"]
  ]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    tableView.dataSource = self
  }
  
  @IBAction func addProperty(_ sender: Any) {
    properties.append(["key": "", "type": "Clear"])
    tableView.reloadData()
  }
  
  @IBAction func deleteProperty(_ sender: Any) {
    if properties.isEmpty {
      return
    }
    if (tableView.selectedRow < 0) {
      properties.remove(at: properties.count - 1)
    } else {
      properties.remove(at: tableView.selectedRow)
    }
    tableView.reloadData()
  }
  
  @IBAction func send(_ sender: Any) {
  }
  
  //MARK: Table view source delegate
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return properties.count
  }
  
  //MARK: Table view delegate
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let `tableColumn` = tableColumn else {
      return nil
    }
    let key: String = properties[row]["key"] as! String
    let type: String = properties[row]["type"] as! String
    let value = properties[row]["value"]
    if let cell = tableView.make(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView {
      switch tableColumn.identifier {
      case "key":
        cell.textField?.stringValue = key
      case "type":
        let comboBox = cell.subviews[0] as! NSComboBox
        comboBox.selectItem(withObjectValue: type)
      case "value":
        switch type {
        case "Clear":
          cell.isHidden = true
        case "String":
          cell.isHidden = false
          cell.textField?.stringValue = value as! String
        case "Number":
          cell.isHidden = false
        case "Boolean":
          cell.isHidden = false
        case "DateTime":
          cell.isHidden = false
        default: ()
        }
      default: ()
      }
      
      return cell
    }
    return nil
  }
  
}
