import Cocoa

// FIXME: trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
class AnalyticsViewController : NSViewController, NSTableViewDataSource, NSTableViewDelegate {

  private enum CellIdentifiers {
    static let keyCellId = "keyCellId"
    static let valueCellId = "valueCellId"
  }

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!

  @IBOutlet weak var name: NSTextField!
  @IBOutlet var setEnabledButton : NSButton?
  @IBOutlet var table : NSTableView?

  private var properties : [String : String] = [String : String]()
  private var textBeforeEditing : String = ""
  private var totalPropsCounter : Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setEnabledButton?.state = appCenter.isAnalyticsEnabled() ? 1 : 0
    table?.delegate = self
    table?.dataSource = self
    NotificationCenter.default.addObserver(self, selector: #selector(self.editingDidBegin), name: .NSControlTextDidBeginEditing, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.editingDidEnd), name: .NSControlTextDidEndEditing, object: nil)
  }

  override func viewWillAppear() {
    setEnabledButton?.state = appCenter.isAnalyticsEnabled() ? 1 : 0;
  }

  override func viewDidDisappear() {
    super.viewDidDisappear()
    NotificationCenter.default.removeObserver(self)
  }

  @IBAction func trackEvent(_ : AnyObject) {
    appCenter.trackEvent(name.stringValue, withProperties: properties)
  }

  @IBAction func trackPage(_ : AnyObject) {
    NSLog("trackPageWithProperties: %d", properties.count)
  }

  @IBAction func addProperty(_ : AnyObject) {
    let newKey = String(format:"key%d",totalPropsCounter)
    let newValue = String(format:"value%d",totalPropsCounter)

    self.properties.updateValue(newValue, forKey: newKey)
    table?.reloadData()

    totalPropsCounter+=1
  }

  @IBAction func deleteProperty(_ : AnyObject) {
    if properties.isEmpty {
      return
    }
    guard let `table` = table else {
      return
    }
    if (table.selectedRow < 0) {
      _ = properties.popFirst()
    } else {
      let key : String = Array(properties.keys)[table.selectedRow]
      _ = properties.removeValue(forKey: key)
    }
    table.reloadData()
  }

  @IBAction func setEnabled(sender : NSButton) {
    appCenter.setAnalyticsEnabled(sender.state == 1)
    sender.state = appCenter.isAnalyticsEnabled() ? 1 : 0
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

    var cellValue : String = ""
    var cellId : String = ""
    let key : String = Array(properties.keys)[row]

    if (tableColumn == tableView.tableColumns[0]) {
      cellValue = key
      cellId = CellIdentifiers.keyCellId
    } else if (tableColumn == tableView.tableColumns[1]) {
      cellValue = properties[key]!
      cellId = CellIdentifiers.valueCellId
    }

    if let cell = tableView.make(withIdentifier: cellId, owner: nil) as? NSTableCellView {
      cell.textField?.stringValue = cellValue
      cell.textField?.isEditable = true
      return cell
    }

    return nil
  }

  //MARK: Text field events

  func editingDidBegin(notification : NSNotification) {
    guard let textField = notification.object as? NSTextField else {
      return
    }
    textBeforeEditing = textField.stringValue
  }

  func editingDidEnd(notification : NSNotification) {
    guard let textField = notification.object as? NSTextField else {
      return
    }

    // If key
    if (properties.keys.contains(textBeforeEditing)) {
      let oldKey : String = textBeforeEditing
      let newKey : String = textField.stringValue
      if let value = properties.removeValue(forKey: oldKey) {
        properties.updateValue(value, forKey: newKey)
      }
    }

    // If value
    else {
      guard let row = table?.row(for: textField) else {
        return
      }
      if row < 0 {
        return
      }
      let key : String = Array(properties.keys)[row]
      properties.updateValue(textField.stringValue, forKey: key)
    }

    table?.reloadData()
  }
}
