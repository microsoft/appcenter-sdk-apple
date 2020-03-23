// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Cocoa

class TransmissionViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!
  var transmissionTargetMapping: [String]?
  var propertyValues: [String: [String]]!
  var collectDeviceIdStates: [String: Bool]!
  
  static var targetsShared: TransmissionTargets?
  let kDeviceIdRow = 0
  let kAppNameRow = 1
  let kAppVersionRow = 2
  let kAppLocaleRow = 3
  let kUserIdRow = 4
  let propertyKeys = ["Collect Device ID", "App Name", "App Version", "App Locale", "User Id"]

  @IBOutlet weak var defaultTable: NSTableView!
  @IBOutlet weak var runtimeTable: NSTableView!
  @IBOutlet weak var child1Table: NSTableView!
  @IBOutlet weak var child2Table: NSTableView!
  @IBOutlet weak var propertiesTable: NSTableView!
  @IBOutlet weak var commonTable: NSTableView!
  @IBOutlet weak var propertySelector: NSSegmentedControl!
  @IBOutlet weak var commonSelector: NSSegmentedControl!
  @IBOutlet var arrayController: NSArrayController!

  private var transmissionTargetSections: [TransmissionTargetSection]?
  private let kEnabledCellRowIndex = 0
  private let kAnalyticsCellRowIndex = 1
  private let kTokenCellRowIndex = 2
  private let kPauseCellRowIndex = 3
  private var runtimePreProperties = [EventProperty]()
  private var child1PreProperties = [EventProperty]()
  private var child2PreProperties = [EventProperty]()
  @objc dynamic var runtimeProperties = [EventProperty]()
  @objc dynamic var child1Properties = [EventProperty]()
  @objc dynamic var child2Properties = [EventProperty]()

  private class TransmissionTargetSection: NSObject {
    static var defaultTransmissionTargetWasEnabled: Bool?

    var token: String?
    var isDefault = false

    func isTransmissionTargetEnabled() -> Bool {
      if isDefault {
        return TransmissionTargets.defaultTransmissionTargetWasEnabled
      } else {
        return getTransmissionTarget()?.isEnabled() ?? false
      }
    }

    func setTransmissionTargetEnabled(_ enabledState: Bool) {
      if !isDefault {
        getTransmissionTarget()!.setEnabled(enabledState)
      }
    }

    func getTransmissionTarget() -> MSAnalyticsTransmissionTarget? {
      if isDefault {
        return nil
      }
      return targetsShared?.transmissionTargets[token!]
    }

    func shouldSendAnalytics() -> Bool {
      if isDefault {
        return targetsShared?.defaultTargetShouldSendAnalyticsEvents() ?? false
      }
      return targetsShared?.targetShouldSendAnalyticsEvents(targetToken: token!) ?? false
    }

    func setShouldSendAnalytics(enabledState: Bool) {
      if isDefault {
        targetsShared!.setShouldDefaultTargetSendAnalyticsEvents(enabledState: enabledState)
      } else {
        targetsShared!.setShouldSendAnalyticsEvents(targetToken: token!, enabledState: enabledState)
      }
    }
 
    func pause() {
      getTransmissionTarget()!.pause()
    }

    func resume() {
      getTransmissionTarget()!.resume()
    }
  }

  class EventProperty : NSObject {
    var target: Int = TransmissionTarget.child1.rawValue
    @objc var key: String = ""
    @objc var type: String = EventPropertyType.string.rawValue
    @objc var string: String = ""
    @objc var double: NSNumber = 0
    @objc var long: NSNumber = 0
    @objc var boolean: Bool = false
    @objc var dateTime: Date = Date.init()
  }

  enum Section : Int {
    case Default = 0
    case Runtime = 1
    case Child1 = 2
    case Child2 = 3
    case TargetProperties = 4
    case CommonSchemaProperties = 5
  }

  enum EventPropertyType : String {
    case string = "String"
    case double = "Double"
    case long = "Long"
    case boolean = "Boolean"
    case dateTime = "DateTime"

    static let allValues = [string, double, long, boolean, dateTime]
  }

  enum CommonSchemaPropertyRow : Int {
    case appName
    case appVersion
    case appLocale
    case userId
  }

  enum cellSubviews : Int {
    case key = 0
    case valueCheck = 1
    case valueText = 2
    case pause = 3
    case resume = 4
  }

  enum TransmissionTarget : Int {
    case child1
    case child2
    case runTime
  }

  override func viewWillAppear() {
    appCenter.startAnalyticsFromLibrary()
    
    // We should initialize the targets only after starting from library,
    // Otherwise channelGroup would be nil.
    // After that we should reload tables data with actual "enabled" states.
    TransmissionViewController.targetsShared = TransmissionTargets.shared
    defaultTable.reloadData()
    runtimeTable.reloadData()
    child1Table.reloadData()
    child2Table.reloadData()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    defaultTable.delegate = self
    defaultTable.dataSource = self
    runtimeTable.delegate = self
    runtimeTable.dataSource = self
    child1Table.delegate = self
    child1Table.dataSource = self
    child2Table.delegate = self
    child2Table.dataSource = self
    propertiesTable.delegate = self
    commonTable.delegate = self
    commonTable.dataSource = self
    commonSelector.selectedSegment = 0
    propertySelector.selectedSegment = 0

    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String

    // Default target section.
    let defaultTargetSection = TransmissionTargetSection()
    defaultTargetSection.isDefault = true
    defaultTargetSection.token = appName.contains("SasquatchMacSwift") ? kMSSwiftTargetToken : kMSObjCTargetToken

    // Runtime target section.
    let runtimeTargetSection = TransmissionTargetSection()
    runtimeTargetSection.token = appName.contains("SasquatchMacSwift") ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken

    // Child 1.
    let child1TargetSection = TransmissionTargetSection()
    child1TargetSection.token = kMSTargetToken1

    // Child 2.
    let child2TargetSection = TransmissionTargetSection()
    child2TargetSection.token = kMSTargetToken2

    transmissionTargetSections = [defaultTargetSection, runtimeTargetSection, child1TargetSection, child2TargetSection]

    // Common schema properties section
    propertyValues = [String: [String]]()
    collectDeviceIdStates = [String: Bool]()
    let parentTargetToken = appName.contains("SasquatchMacSwift") ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken
    for token in [parentTargetToken, kMSTargetToken1, kMSTargetToken2] {
      propertyValues[token] = Array(repeating: "", count: propertyKeys.count)
      collectDeviceIdStates[token] = false
    }
    transmissionTargetMapping = [kMSTargetToken1, kMSTargetToken2, parentTargetToken]
    commonSelector.target = self
    commonSelector.action = #selector(onSegmentSelected)

    // Target properties section
    propertySelector.target = self
    propertySelector.action = #selector(onSegmentSelected)
  }

  func numberOfRows(in tableView: NSTableView) -> Int {
    if tableView == defaultTable {
      return 3
    }
    else if tableView == commonTable {
      return 5
    }
    return 4
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    
    // Target properties section
    if(tableView.tag == Section.TargetProperties.rawValue) {
      guard let identifier = tableColumn?.identifier else {
        return nil
      }
      let view = tableView.makeView(withIdentifier: identifier, owner: nil)
      if (identifier.rawValue == "value") {
        let eventProperties = arrayController.content as! [EventProperty]
        updateValue(property: eventProperties[row], cell: view as! NSTableCellView)
      }
      return view
    }

    tableView.headerView = nil

    // Common schema properties section
    if(tableView.tag == Section.CommonSchemaProperties.rawValue) {
      if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "property"), owner: nil) as? NSTableCellView {
        let property = propertyAtRow(row: row)
        switch (row) {
        case kDeviceIdRow:
          let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
          key.stringValue = property.key
          let value: NSButton = cell.subviews[cellSubviews.valueCheck.rawValue] as! NSButton
          let selectedTarget = selectedTransmissionTarget(commonSelector)
          value.state = collectDeviceIdStates[selectedTarget!]! ? .on : .off
          value.isEnabled = !((value.state as NSNumber).boolValue)
          value.target = self
          value.action = #selector(collectDeviceIdSwitchCellEnabled)
          cell.subviews[cellSubviews.valueText.rawValue].isHidden = true
          return cell   
        case kAppNameRow:
          let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
          key.stringValue = property.key
          let value: NSTextField = cell.subviews[cellSubviews.valueText.rawValue] as! NSTextField
          value.stringValue = property.value
          value.delegate = self
          cell.subviews[cellSubviews.valueCheck.rawValue].isHidden = true
          return cell
        case kAppVersionRow:
          let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
          key.stringValue = property.key
          let value: NSTextField = cell.subviews[cellSubviews.valueText.rawValue] as! NSTextField
          value.stringValue = property.value
          value.delegate = self
          cell.subviews[cellSubviews.valueCheck.rawValue].isHidden = true
          return cell
        case kAppLocaleRow:
          let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
          key.stringValue = property.key
          let value: NSTextField = cell.subviews[cellSubviews.valueText.rawValue] as! NSTextField
          value.stringValue = property.value
          value.delegate = self
          cell.subviews[cellSubviews.valueCheck.rawValue].isHidden = true
          return cell
        case kUserIdRow:
          let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
          key.stringValue = property.key
          let value: NSTextField = cell.subviews[cellSubviews.valueText.rawValue] as! NSTextField
          value.stringValue = property.value
          value.delegate = self
          cell.subviews[cellSubviews.valueCheck.rawValue].isHidden = true
          return cell
        default:
           return nil
        }
      }
      return nil
    }

    // Transmission target section
    if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "target"), owner: nil) as? NSTableCellView {
      let section = transmissionTargetSections![tableView.tag]
      switch (row) {
      case kEnabledCellRowIndex:
        let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
        key.stringValue = "Set Enabled"
        let value: NSButton = cell.subviews[cellSubviews.valueCheck.rawValue] as! NSButton
        value.state = section.isTransmissionTargetEnabled() ? .on : .off
        value.isEnabled = tableView.tag != Section.Default.rawValue
        value.target = self
        value.action = #selector(targetEnabledSwitchValueChanged)
        cell.subviews[cellSubviews.valueText.rawValue].isHidden = true
        return cell     
      case kAnalyticsCellRowIndex:
        let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
        key.stringValue = "Analytics Events"
        let value: NSButton = cell.subviews[cellSubviews.valueCheck.rawValue] as! NSButton
        value.state = section.shouldSendAnalytics() ? .on : .off
        value.target = self
        value.action = #selector(targetShouldSendAnalyticsSwitchValueChanged)
        cell.subviews[cellSubviews.valueText.rawValue].isHidden = true
        return cell
      case kTokenCellRowIndex:
        let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
        key.stringValue = "Token"
        let value: NSTextField = cell.subviews[cellSubviews.valueText.rawValue] as! NSTextField
        value.stringValue = section.token!
        cell.subviews[cellSubviews.valueCheck.rawValue].isHidden = true
        return cell
      case kPauseCellRowIndex:
        cell.subviews[cellSubviews.key.rawValue].isHidden = true
        cell.subviews[cellSubviews.valueCheck.rawValue].isHidden = true
        cell.subviews[cellSubviews.valueText.rawValue].isHidden = true
        let pause: NSButton = cell.subviews[cellSubviews.pause.rawValue] as! NSButton
        pause.isHidden = false
        pause.target = self
        pause.action = #selector(TransmissionViewController.pause)
        let resume: NSButton = cell.subviews[cellSubviews.resume.rawValue] as! NSButton
        resume.isHidden = false
        resume.target = self
        resume.action = #selector(TransmissionViewController.resume)
        return cell
      default:
        return nil
      }
    }
    return nil
  }

  private func getCellSection(forView view: NSView) -> Int {
    guard let tableView = view.superview!.superview?.superview as? NSTableView else {
      return -1
    }
    return tableView.tag
  }

  public func selectedTransmissionTarget(_ sender: NSSegmentedControl) -> String! {
    return transmissionTargetMapping![sender.selectedSegment]
  }

  @objc func onSegmentSelected(_ sender: NSSegmentedControl) {
    if(sender == commonSelector) {
      commonTable.reloadData()
    }
    else if(sender == propertySelector) {
      switch propertySelector.selectedSegment {
      case TransmissionTarget.child1.rawValue:
        arrayController.bind(NSBindingName(rawValue: "contentArray"), to: self, withKeyPath:"child1Properties", options: nil)
        break
      case TransmissionTarget.child2.rawValue:
        arrayController.bind(NSBindingName(rawValue: "contentArray"), to: self, withKeyPath:"child2Properties", options: nil)
        break
      case TransmissionTarget.runTime.rawValue:
        arrayController.bind(NSBindingName(rawValue: "contentArray"), to: self, withKeyPath:"runtimeProperties", options: nil)
        break
      default:
        break
      }
    }
  }

  // Transmission target section
  @objc func targetEnabledSwitchValueChanged(sender: NSButton!) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    let state = (sender!.state as NSNumber).boolValue
    section.setTransmissionTargetEnabled(state)
    if (sectionIndex == Section.Default.rawValue) {
      section.setTransmissionTargetEnabled(state)
    }
    else if sectionIndex == Section.Runtime.rawValue {
      section.setTransmissionTargetEnabled(state)
      var tableView = child1Table
      for childSectionIndex in 2...3 {
        if(childSectionIndex == 3) {
          tableView=child2Table
        }
        guard let childCell = tableView?.view(atColumn: 0, row: kEnabledCellRowIndex, makeIfNecessary: false) as? NSTableCellView else {
          continue
        }
        let childSwitch: NSButton? = childCell.subviews[cellSubviews.valueCheck.rawValue] as? NSButton
        let childTarget = transmissionTargetSections![childSectionIndex].getTransmissionTarget()
        childSwitch!.state = (childTarget?.isEnabled())! ? .on : .off
        childSwitch!.isEnabled = state
      }
    }
    else if sectionIndex == Section.Child1.rawValue || sectionIndex == Section.Child2.rawValue {
      let switchEnabled = (sender!.state as NSNumber).boolValue
      section.setTransmissionTargetEnabled(switchEnabled)
      if switchEnabled && !section.isTransmissionTargetEnabled() {
  
        // Switch tried to enable the transmission target but it didn't work.
        sender!.state = .off
        section.setTransmissionTargetEnabled(false)
        sender!.isEnabled = false
      }
    }
  }

  @objc func targetShouldSendAnalyticsSwitchValueChanged(sender: NSButton!) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    let state = (sender!.state as NSNumber).boolValue
    section.setShouldSendAnalytics(enabledState: state)
  }

  @objc func pause(_ sender: NSButton) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    section.pause()
  }

  @objc func resume(_ sender: NSButton) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    section.resume()
  }

  // Common schema properties section
  @objc func collectDeviceIdSwitchCellEnabled(sender: NSButton?) {
    sender!.isEnabled = false

    // Update the transmission target.
    let selectedTarget = selectedTransmissionTarget(commonSelector)
    let target = TransmissionViewController.targetsShared!.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.collectDeviceId()

    // Update in memory state for display.
    collectDeviceIdStates[selectedTarget!] = true
  }

  func controlTextDidChange(_ obj: Notification) {
    let text = obj.object as? NSTextField
    let tag = getCellSection(forView: text!)
    if(tag == Section.CommonSchemaProperties.rawValue) {
      propertyValueChanged(sender: text)
    }
  }

  func getCellRow(forTextField textField: NSTextField!) -> Int {
    let cell = textField.superview as! NSTableCellView
    let key:NSTextField  =  cell.subviews[cellSubviews.key.rawValue] as! NSTextField
    switch key.stringValue {
    case propertyKeys[1]:
      return kAppNameRow
    case propertyKeys[2]:
      return kAppVersionRow
    case propertyKeys[3]:
      return kAppLocaleRow
    case propertyKeys[4]:
      return kUserIdRow
    default:
      return 0
    }
  }
 
  func propertyValueChanged(sender: NSTextField!) {
    let selectedTarget = selectedTransmissionTarget(commonSelector)
    let propertyIndex = getCellRow(forTextField: sender)
    let target = TransmissionViewController.targetsShared!.transmissionTargets[selectedTarget!]!
    propertyValues[selectedTarget!]![propertyIndex] = sender.stringValue
    let value: String? = sender.stringValue.isEmpty ? nil : sender.stringValue
    switch CommonSchemaPropertyRow(rawValue: propertyIndex - 1)! {
    case .appName:
      target.propertyConfigurator.setAppName(value)
      break
    case .appVersion:
      target.propertyConfigurator.setAppVersion(value)
      break
    case .appLocale:
      target.propertyConfigurator.setAppLocale(value)
      break
    case .userId:
      target.propertyConfigurator.setUserId(value)
      break
    }
  }

  func propertyAtRow(row: Int) -> (key: String, value: String) {
    let selectedTarget = selectedTransmissionTarget(commonSelector)
    let value = propertyValues[selectedTarget!]![row]
    return (propertyKeys[row], value)
  }

  // Target properties section
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

  @IBAction func addProperty(_ sender: NSButton) {
    let property = EventProperty()
    let targetEventProperties = arrayController.content as! [EventProperty]
    let count = targetEventProperties.count
    property.target = propertySelector.selectedSegment
    property.key = "key\(count)"
    property.string = "value\(count)"
    property.addObserver(self, forKeyPath: #keyPath(EventProperty.type), options: .new, context: nil)
    property.addObserver(self, forKeyPath: #keyPath(EventProperty.key), options: .new, context: nil)
    property.addObserver(self, forKeyPath: #keyPath(EventProperty.string), options: .new, context: nil)
    property.addObserver(self, forKeyPath: #keyPath(EventProperty.double), options: .new, context: nil)
    property.addObserver(self, forKeyPath: #keyPath(EventProperty.long), options: .new, context: nil)
    property.addObserver(self, forKeyPath: #keyPath(EventProperty.boolean), options: .new, context: nil)
    property.addObserver(self, forKeyPath: #keyPath(EventProperty.dateTime), options: .new, context: nil)
    arrayController.addObject(property)
    let selectedTarget = selectedTransmissionTarget(propertySelector)
    let target = TransmissionViewController.targetsShared!.transmissionTargets[selectedTarget!]!
    setEventPropertyState(property, forTarget: target)

    let propertyNoObserver = EventProperty()
    propertyNoObserver.key = "key\(count)"
    propertyNoObserver.string = "value\(count)"
    switch propertySelector.selectedSegment {
    case TransmissionTarget.child1.rawValue:
      child1PreProperties.append(propertyNoObserver)
      break
    case TransmissionTarget.child2.rawValue:
      child2PreProperties.append(propertyNoObserver)
      break
    case TransmissionTarget.runTime.rawValue:
      runtimePreProperties.append(propertyNoObserver)
      break
    default:
      break
    }
  }

  @IBAction func deleteProperty(_ sender: NSButton) {
    if let selectedProperty = arrayController.selectedObjects.first as? EventProperty {
      let index = arrayController.selectionIndex
      switch propertySelector.selectedSegment {
      case TransmissionTarget.child1.rawValue:
        child1PreProperties.remove(at: index)
        break
      case TransmissionTarget.child2.rawValue:
        child2PreProperties.remove(at: index)
        break
      case TransmissionTarget.runTime.rawValue:
        runtimePreProperties.remove(at: index)
        break
      default:
        break
      }
      arrayController.removeObject(selectedProperty)
      selectedProperty.removeObserver(self, forKeyPath: #keyPath(EventProperty.type), context: nil)
      let selectedTarget = selectedTransmissionTarget(propertySelector)
      let target = TransmissionViewController.targetsShared!.transmissionTargets[selectedTarget!]!
      target.propertyConfigurator.removeEventProperty(forKey: selectedProperty.key)
    }
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard let property = object as? EventProperty else {
      return
    }
    var targetEventProperties = [EventProperty]()
    let currentTarget = property.target
    switch currentTarget {
    case TransmissionTarget.child1.rawValue:
      targetEventProperties = child1Properties
      break
    case TransmissionTarget.child2.rawValue:
      targetEventProperties = child2Properties
      break
    case TransmissionTarget.runTime.rawValue:
      targetEventProperties = runtimeProperties
      break
    default:
      break
    }

    guard let row = targetEventProperties.index(of: property) else {
      return
    }
    if(keyPath == #keyPath(EventProperty.type)) {
      let column = propertiesTable?.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "value"))
      guard let cell = propertiesTable?.view(atColumn: column!, row: row, makeIfNecessary: false) as? NSTableCellView else {
        return
      }
      updateValue(property: property, cell: cell)
    }
    var key = ""
    let propertyNoObserver = EventProperty()
    propertyNoObserver.target = property.target
    propertyNoObserver.key = property.key
    propertyNoObserver.type = property.type
    propertyNoObserver.string = property.string
    propertyNoObserver.double = property.double
    propertyNoObserver.long = property.long
    propertyNoObserver.boolean = property.boolean
    propertyNoObserver.dateTime = property.dateTime
    switch currentTarget {
    case TransmissionTarget.child1.rawValue:
      key = child1PreProperties[row].key
      child1PreProperties[row] = propertyNoObserver
      break
    case TransmissionTarget.child2.rawValue:
      key = child2PreProperties[row].key
      child2PreProperties[row] = propertyNoObserver
      break
    case TransmissionTarget.runTime.rawValue:
      key = runtimePreProperties[row].key
      runtimePreProperties[row] = propertyNoObserver
      break
    default:
      break
    }
    let selectedTarget = transmissionTargetMapping![currentTarget]
    let target = TransmissionViewController.targetsShared!.transmissionTargets[selectedTarget]!
    target.propertyConfigurator.removeEventProperty(forKey: key)
    setEventPropertyState(property, forTarget: target)
  }

  func setEventPropertyState(_ property: EventProperty, forTarget target: MSAnalyticsTransmissionTarget) {
    let type = EventPropertyType(rawValue: property.type)!
    switch type {
    case .string:
      target.propertyConfigurator.setEventProperty(property.string , forKey: property.key)
    case .boolean:
      target.propertyConfigurator.setEventProperty(property.boolean , forKey: property.key)
    case .double:
      target.propertyConfigurator.setEventProperty(property.double.doubleValue, forKey: property.key)
    case .long:
      target.propertyConfigurator.setEventProperty(property.long.int64Value, forKey: property.key)
    case .dateTime:
      target.propertyConfigurator.setEventProperty(property.dateTime , forKey: property.key)
    }
  }
}
