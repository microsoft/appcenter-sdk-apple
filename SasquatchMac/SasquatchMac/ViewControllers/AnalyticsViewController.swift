import Cocoa

// FIXME: trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
class AnalyticsViewController : NSViewController, NSTableViewDataSource, NSTableViewDelegate {

  private enum CellIdentifiers {
    static let keyCellId = "keyCellId"
    static let valueCellId = "valueCellId"
  }

    enum Priority: String {
        case Default = "Default"
        case Normal = "Normal"
        case Critical = "Critical"
        case Invalid = "Invalid"

        var flags: MSFlags {
            switch self {
            case .Normal:
                return [.persistenceNormal]
            case .Critical:
                return [.persistenceCritical]
            case .Invalid:
                return MSFlags.init(rawValue: 42)
            default:
                return []
            }
        }

        static let allValues = [Default, Normal, Critical, Invalid]
    }

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!

  @IBOutlet weak var name: NSTextField!
  @IBOutlet var setEnabledButton : NSButton?
  @IBOutlet var table : NSTableView?
  @IBOutlet weak var pause: NSButton!
  @IBOutlet weak var resume: NSButton!
  @IBOutlet weak var priorityValue: NSComboBox!
  @IBOutlet weak var countLabel: NSTextField!
  @IBOutlet weak var countSlider: NSSlider!

  private var properties : [String : String] = [String : String]()
  private var textBeforeEditing : String = ""
  private var totalPropsCounter : Int = 0
  private var priority = Priority.Default

  override func viewDidLoad() {
    super.viewDidLoad()
    setEnabledButton?.state = appCenter.isAnalyticsEnabled() ? 1 : 0
    table?.delegate = self
    table?.dataSource = self
    NotificationCenter.default.addObserver(self, selector: #selector(self.editingDidBegin), name: .NSControlTextDidBeginEditing, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.editingDidEnd), name: .NSControlTextDidEndEditing, object: nil)
    self.countLabel.stringValue = "Count: \(Int(countSlider.intValue))"
  }

  override func viewWillAppear() {
    setEnabledButton?.state = appCenter.isAnalyticsEnabled() ? 1 : 0;
  }

  override func viewDidDisappear() {
    super.viewDidDisappear()
    NotificationCenter.default.removeObserver(self)
  }

  @IBAction func trackEvent(_ : AnyObject) {
    let eventName = name.stringValue
    for _ in 0..<Int(countSlider.intValue) {
      if priority != .Default {
        appCenter.trackEvent(eventName, withProperties: properties, flags: priority.flags)
      } else {
        appCenter.trackEvent(eventName, withProperties: properties)
      }
    }
  }

  @IBAction func resume(_ sender: NSButton) {
    appCenter.resume()
  }

  @IBAction func pause(_ sender: NSButton) {
    appCenter.pause()
  }

  @IBAction func countChanged(_ sender: Any) {
    self.countLabel.stringValue = "Count: \(Int(countSlider.intValue))"
  }

  @IBAction func priorityChanged(_ sender: NSComboBox) {
    switch(self.priorityValue.stringValue)
    {
    case "Normal":
        self.priority=Priority.Normal
    case "Critical":
        self.priority=Priority.Critical
    case "Invalid":
        self.priority=Priority.Invalid
    default:
        self.priority=Priority.Default
    }
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
