import Cocoa

class TransmissionViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!
  var transmissionTargetMapping: [String]?
  var propertyValues: [String: [String]]!
  var collectDeviceIdStates: [String: Bool]!

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
  dynamic var eventProperties = [EventProperty]()

  private class TransmissionTargetSection: NSObject {
    static var defaultTransmissionTargetIsEnabled: Bool?

    var token: String?
    var isDefault = false

    func isTransmissionTargetEnabled() -> Bool {
      if isDefault {
        return TransmissionTargets.shared.defaultTransmissionTargetIsEnabled
      } else {
        return getTransmissionTarget()!.isEnabled()
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
      } else {
        return TransmissionTargets.shared.transmissionTargets[token!]
      }
    }

    func shouldSendAnalytics() -> Bool {
      if isDefault {
        return TransmissionTargets.shared.defaultTargetShouldSendAnalyticsEvents()
      } else {
        return TransmissionTargets.shared.targetShouldSendAnalyticsEvents(targetToken: token!)
      }
    }

    func setShouldSendAnalytics(enabledState: Bool) {
      if isDefault {
        TransmissionTargets.shared.setShouldDefaultTargetSendAnalyticsEvents(enabledState: enabledState)
      } else {
        TransmissionTargets.shared.setShouldSendAnalyticsEvents(targetToken: token!, enabledState: enabledState)
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
    var key: String = ""
    var type: String = EventPropertyType.string.rawValue
    var string: String = ""
    var double: NSNumber = 0
    var long: NSNumber = 0
    var boolean: Bool = false
    var dateTime: Date = Date.init()
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

  override func viewWillAppear() {
    appCenter.startAnalyticsFromLibrary()
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

    NotificationCenter.default.addObserver(self, selector: #selector(self.editingDidEnd), name: .NSControlTextDidEndEditing, object: nil)
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

    //Common schema properties section
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
    tableView.headerView = nil

    // Common schema properties section
    if(tableView.tag == Section.CommonSchemaProperties.rawValue) {
      if let cell = tableView.make(withIdentifier: "property", owner: nil) as? NSTableCellView {
        let property = propertyAtRow(row: row)
        switch (row) {
        case kDeviceIdRow:
          let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
          key.stringValue = property.key
          let value: NSButton = cell.subviews[cellSubviews.valueCheck.rawValue] as! NSButton
          let selectedTarget = selectedTransmissionTarget(commonSelector)
          value.state = (collectDeviceIdStates[selectedTarget!]?.hashValue)!
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
          cell.subviews[cellSubviews.valueCheck.rawValue].isHidden = true
          return cell
        case kAppVersionRow:
          let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
          key.stringValue = property.key
          let value: NSTextField = cell.subviews[cellSubviews.valueText.rawValue] as! NSTextField
          value.stringValue = property.value
          cell.subviews[cellSubviews.valueCheck.rawValue].isHidden = true
          return cell
        case kAppLocaleRow:
          let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
          key.stringValue = property.key
          let value: NSTextField = cell.subviews[cellSubviews.valueText.rawValue] as! NSTextField
          value.stringValue = property.value
          cell.subviews[cellSubviews.valueCheck.rawValue].isHidden = true
          return cell
        case kUserIdRow:
          let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
          key.stringValue = property.key
          let value: NSTextField = cell.subviews[cellSubviews.valueText.rawValue] as! NSTextField
          value.stringValue = property.value
          cell.subviews[cellSubviews.valueCheck.rawValue].isHidden = true
          return cell
        default:
           return nil
        }
      }
      return nil
    }

    //Transmission target section
    if let cell = tableView.make(withIdentifier: "target", owner: nil) as? NSTableCellView {
      let section = transmissionTargetSections![tableView.tag]
      switch (row) {
      case kEnabledCellRowIndex:
        let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
        key.stringValue = "Set Enabled"
        let value: NSButton = cell.subviews[cellSubviews.valueCheck.rawValue] as! NSButton
        value.state = section.isTransmissionTargetEnabled().hashValue
        value.isEnabled = tableView.tag != Section.Default.rawValue
        value.target = self
        value.action = #selector(targetEnabledSwitchValueChanged)
        cell.subviews[cellSubviews.valueText.rawValue].isHidden = true
        return cell     
      case kAnalyticsCellRowIndex:
        let key: NSTextField = cell.subviews[cellSubviews.key.rawValue] as! NSTextField
        key.stringValue = "Analytics Events"
        let value: NSButton = cell.subviews[cellSubviews.valueCheck.rawValue] as! NSButton
        value.state = section.shouldSendAnalytics().hashValue
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

  func onSegmentSelected(_ sender: NSSegmentedControl) {
    if(sender == commonSelector) {
      commonTable.reloadData()
    }
  }

  //Transmission target section
  func targetEnabledSwitchValueChanged(sender: NSButton!) {
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
        childSwitch!.state = (childTarget?.isEnabled().hashValue)!
        childSwitch!.isEnabled = state
      }
    }
    else if sectionIndex == Section.Child1.rawValue || sectionIndex == Section.Child2.rawValue {
      let switchEnabled = (sender!.state as NSNumber).boolValue
      section.setTransmissionTargetEnabled(switchEnabled)
      if switchEnabled && !section.isTransmissionTargetEnabled() {
  
        // Switch tried to enable the transmission target but it didn't work.
        sender!.state = 0
        section.setTransmissionTargetEnabled(false)
        sender!.isEnabled = false
      }
    }
  }

  func targetShouldSendAnalyticsSwitchValueChanged(sender: NSButton!) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    let state = (sender!.state as NSNumber).boolValue
    section.setShouldSendAnalytics(enabledState: state)
  }

  func pause(_ sender: NSButton) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    section.pause()
  }

  func resume(_ sender: NSButton) {
    let sectionIndex = getCellSection(forView: sender)
    let section = transmissionTargetSections![sectionIndex]
    section.resume()
  }

  // Common schema properties section
  @objc func collectDeviceIdSwitchCellEnabled(sender: NSButton?) {
    sender!.isEnabled = false

    // Update the transmission target.
    let selectedTarget = selectedTransmissionTarget(commonSelector)
    let target = TransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    target.propertyConfigurator.collectDeviceId()

    // Update in memory state for display.
    collectDeviceIdStates[selectedTarget!] = true
  }

  @objc func editingDidEnd(notification : NSNotification) {
    guard let textField = notification.object as? NSTextField else {
      return
    }
    let tag = getCellSection(forView: textField)
    if(tag == Section.CommonSchemaProperties.rawValue){
      propertyValueChanged(sender: textField)
    }
    return
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
    let target = TransmissionTargets.shared.transmissionTargets[selectedTarget!]!
    propertyValues[selectedTarget!]![propertyIndex] = sender.stringValue
    switch CommonSchemaPropertyRow(rawValue: propertyIndex - 1)! {
    case .appName:
      target.propertyConfigurator.setAppName(sender.stringValue)
      break
    case .appVersion:
      target.propertyConfigurator.setAppVersion(sender.stringValue)
      break
    case .appLocale:
      target.propertyConfigurator.setAppLocale(sender.stringValue)
      break
    case .userId:
      target.propertyConfigurator.setUserId(sender.stringValue)
      break
    }
  }

  func propertyAtRow(row: Int) -> (key: String, value: String) {
    let selectedTarget = selectedTransmissionTarget(commonSelector)
    let value = propertyValues[selectedTarget!]![row]
    return (propertyKeys[row], value)
  }
}
