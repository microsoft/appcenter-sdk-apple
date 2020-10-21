// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Cocoa

// FIXME: trackPage has been hidden in Analytics temporarily. Use internal until the feature comes back.
class AnalyticsViewController : NSViewController, NSTableViewDataSource, NSTableViewDelegate {

  class EventProperty : NSObject {
    @objc var key: String = ""
    @objc var type: String = EventPropertyType.string.rawValue
    @objc var string: String = ""
    @objc var double: NSNumber = 0
    @objc var long: NSNumber = 0
    @objc var boolean: Bool = false
    @objc var dateTime: Date = Date.init()
  }

  enum EventPropertyType : String {
    case string = "String"
    case double = "Double"
    case long = "Long"
    case boolean = "Boolean"
    case dateTime = "DateTime"

    static let allValues = [string, double, long, boolean, dateTime]
  }

  enum Priority: String {
    case defaultType = "Default"
    case normal = "Normal"
    case critical = "Critical"
    case invalid = "Invalid"

    var flags: Flags {
      switch self {
      case .normal:
        return [.normal]
      case .critical:
        return [.critical]
      case .invalid:
        return Flags.init(rawValue: 42)
      default:
        return []
      }
    }

    static let allValues = [defaultType, normal, critical, invalid]
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
  private var priority = Priority.defaultType
  @objc dynamic var eventProperties = [EventProperty]()

  override func viewDidLoad() {
    super.viewDidLoad()
    setEnabledButton?.state = appCenter.isAnalyticsEnabled() ? .on : .off
    table?.delegate = self
    self.countLabel.stringValue = "Count: \(Int(countSlider.intValue))"
  }

  override func viewWillAppear() {
    setEnabledButton?.state = appCenter.isAnalyticsEnabled() ? .on : .off
  }

  override func viewDidDisappear() {
    super.viewDidDisappear()
    NotificationCenter.default.removeObserver(self)
  }

  @IBAction func trackEvent(_ : AnyObject) {
    let eventProperties = eventPropertiesSet()
    let eventName = name.stringValue
    for _ in 0..<Int(countSlider.intValue) {
      if let properties = eventProperties as? EventProperties {
        if priority != .defaultType {
          appCenter.trackEvent(eventName, withTypedProperties: properties, flags: priority.flags)
        } else {
          appCenter.trackEvent(eventName, withTypedProperties: properties)
        }
      } else if let dictionary = eventProperties as? [String: String] {
        if priority != .defaultType {
          appCenter.trackEvent(eventName, withProperties: dictionary, flags: priority.flags)
        } else {
          appCenter.trackEvent(eventName, withProperties: dictionary)
        }
      } else {
        if priority != .defaultType {
          appCenter.trackEvent(eventName, withTypedProperties: nil, flags: priority.flags)
        } else {
          appCenter.trackEvent(eventName)
        }
      }
      for targetToken in TransmissionTargets.shared.transmissionTargets.keys {
        if TransmissionTargets.shared.targetShouldSendAnalyticsEvents(targetToken: targetToken) {
          let target = TransmissionTargets.shared.transmissionTargets[targetToken]!
          if let properties = eventProperties as? EventProperties {
            if priority != .defaultType {
              target.trackEvent(eventName, withProperties: properties, flags: priority.flags)
            } else {
              target.trackEvent(eventName, withProperties: properties)
            }
          } else if let dictionary = eventProperties as? [String: String] {
            if priority != .defaultType {
              target.trackEvent(eventName, withProperties: dictionary, flags: priority.flags)
            } else {
              target.trackEvent(eventName, withProperties: dictionary)
            }
          } else {
            if priority != .defaultType {
              target.trackEvent(eventName, withProperties: [:], flags: priority.flags)
            } else {
              target.trackEvent(eventName)
            }
          }
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
    self.priority = Priority(rawValue: self.priorityValue.stringValue)!
  }

  @IBAction func trackPage(_ : AnyObject) {
    NSLog("trackPageWithProperties: %d", eventProperties.count)
  }

  @IBAction func addProperty(_ : AnyObject) {
    let property = EventProperty()
    let eventProperties = arrayController.content as! [EventProperty]
    let count = eventProperties.count
    property.key = "key\(count)"
    property.string = "value\(count)"
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
    appCenter.setAnalyticsEnabled(sender.state == .on)
    sender.state = appCenter.isAnalyticsEnabled() ? .on : .off
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let identifier = tableColumn?.identifier else {
      return nil
    }
    let view = tableView.makeView(withIdentifier: identifier, owner: self)
    if (identifier.rawValue == "value") {
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
    let column = table?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "value"))
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
    let properties = EventProperties()
    for property in eventProperties {
      let key = property.key
      guard let type = EventPropertyType(rawValue: property.type) else {
        continue
      }
      switch type {
      case .string:
        properties.setEventProperty(property.string, forKey: key);
        propertyDictionary[property.key] = property.string
      case .double:
        properties.setEventProperty(property.double.doubleValue, forKey: key)
        onlyStrings = false
      case .long:
        properties.setEventProperty(property.long.int64Value, forKey: key)
        onlyStrings = false
      case .boolean:
        properties.setEventProperty(property.boolean, forKey: key)
        onlyStrings = false
      case .dateTime:
        properties.setEventProperty(property.dateTime, forKey: key)
        onlyStrings = false
      }
    }
    return onlyStrings ? propertyDictionary : properties
  }
}
