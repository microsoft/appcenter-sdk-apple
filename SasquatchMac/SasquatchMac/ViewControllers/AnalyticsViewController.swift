import Cocoa

// FIXME: trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
class AnalyticsViewController : NSViewController, NSTableViewDataSource, NSTableViewDelegate {

  class EventProperty : NSObject {
    var key: String = ""
    var type: String = EventPropertyType.String.rawValue
    var string: String = ""
    var double: NSNumber = 0
    var long: NSNumber = 0
    var boolean: Bool = false
    var dateTime: Date = Date.init()
  }

  enum EventPropertyType : String {
    case String = "String"
    case Double = "Double"
    case Long = "Long"
    case Boolean = "Boolean"
    case DateTime = "DateTime"

    static let allValues = [String, Double, Long, Boolean, DateTime]
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
  @IBOutlet var arrayController: NSArrayController!

  private var textBeforeEditing : String = ""
  private var totalPropsCounter : Int = 0
  private var priority = Priority.Default
  dynamic var eventProperties = [EventProperty]()

  override func viewDidLoad() {
    super.viewDidLoad()
    setEnabledButton?.state = appCenter.isAnalyticsEnabled() ? 1 : 0
    table?.delegate = self
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
    let eventProperties = eventPropertiesSet()
    let eventName = name.stringValue
    for _ in 0..<Int(countSlider.intValue) {
      if let properties = eventProperties as? MSEventProperties {
        if priority != .Default {
          appCenter.trackEvent(eventName, withTypedProperties: properties, flags: priority.flags)
        } else {
          appCenter.trackEvent(eventName, withTypedProperties: properties)
        }
      } else if let dictionary = eventProperties as? [String: String] {
        if priority != .Default {
          appCenter.trackEvent(eventName, withProperties: dictionary, flags: priority.flags)
        } else {
          appCenter.trackEvent(eventName, withProperties: dictionary)
        }
      } else {
        if priority != .Default {
          appCenter.trackEvent(eventName, withTypedProperties: nil, flags: priority.flags)
        } else {
          appCenter.trackEvent(eventName)
        }
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
    switch (self.priorityValue.stringValue) {
    case Priority.Normal.rawValue:
      self.priority = Priority.Normal
    case Priority.Critical.rawValue:
      self.priority = Priority.Critical
    case Priority.Invalid.rawValue:
      self.priority = Priority.Invalid
    default:
      self.priority = Priority.Default
    }
  }

  @IBAction func trackPage(_ : AnyObject) {
    NSLog("trackPageWithProperties: %d", eventProperties.count)
  }

  @IBAction func addProperty(_ : AnyObject) {
    let property = EventProperty()
    property.addObserver(self, forKeyPath: #keyPath(EventProperty.type), options: .new, context: nil)
    arrayController.addObject(property)
  }

  @IBAction func deleteProperty(_ : AnyObject) {
    if let selectedProperty = arrayController.selectedObjects.first as? EventProperty {
      arrayController.removeObject(selectedProperty)
      selectedProperty.removeObserver(self, forKeyPath: #keyPath(EventProperty.type), context: nil)
    }
  }

  @IBAction func setEnabled(sender : NSButton) {
    appCenter.setAnalyticsEnabled(sender.state == 1)
    sender.state = appCenter.isAnalyticsEnabled() ? 1 : 0
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let identifier = tableColumn?.identifier else {
      return nil
    }
    let view = tableView.make(withIdentifier: identifier, owner: self)
    if (identifier == "value") {
      updateValue(property: eventProperties[row], cell: view as! NSTableCellView)
    }
    return view
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard let property = object as? EventProperty else {
      return
    }
    guard let row = eventProperties.index(of: property) else {
      return
    }
    let column = table?.column(withIdentifier: "value")
    guard let cell = table?.view(atColumn: column!, row: row, makeIfNecessary: false) as? NSTableCellView else {
      return
    }
    updateValue(property: property, cell: cell)
  }

  func updateValue(property: EventProperty, cell: NSTableCellView) {
    cell.isHidden = false
    for subview in cell.subviews {
      subview.isHidden = true
    }
    guard let type = EventPropertyType(rawValue: property.type) else {
      return
    }
    if let view = cell.viewWithTag(EventPropertyType.allValues.index(of: type)!) {
      view.isHidden = false
    } else {
      cell.isHidden = true
    }
  }

  func eventPropertiesSet() -> Any? {
    if eventProperties.count < 1 {
      return nil
    }
    var onlyStrings = true
    var propertyDictionary = [String: String]()
    let properties = MSEventProperties()
    for property in eventProperties {
      let key = property.key
      guard let type = EventPropertyType(rawValue: property.type) else {
        continue
      }
      switch type {
      case .String:
        properties.setEventProperty(property.string, forKey: key);
        propertyDictionary[property.key] = property.string
      case .Double:
        properties.setEventProperty(property.double.doubleValue, forKey: key)
        onlyStrings = false
      case .Long:
        properties.setEventProperty(property.long.int64Value, forKey: key)
        onlyStrings = false
      case .Boolean:
        properties.setEventProperty(property.boolean, forKey: key)
        onlyStrings = false
      case .DateTime:
        properties.setEventProperty(property.dateTime, forKey: key)
        onlyStrings = false
      }
    }
    return onlyStrings ? propertyDictionary : properties
  }
}
