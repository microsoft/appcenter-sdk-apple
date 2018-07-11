import UIKit

private var kPropertiesSection: Int = 2

class MSAnalyticsViewController: UITableViewController, AppCenterProtocol {
  
  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var oneCollectorEnabled: UISwitch!
  @IBOutlet weak var eventName: UITextField!
  @IBOutlet weak var pageName: UITextField!
  @IBOutlet weak var selectedChildTargetTokenLabel: UILabel!

  var appCenter: AppCenterDelegate!
  var properties: [String: [(String, String)]]!
  var eventPropertiesIdentifier = "Event Arguments"
  weak var transmissionTargetSelectorCell: MSAnalyticsTranmissionTargetSelectorViewCell?
  weak var addPropertyCell: MSAnalyticsPropertyTableViewCell?
  let propertyIndentationLevel = 1
  let defaultIndentationLevel = 0
  var propertyCounter = 0

  override func viewDidLoad() {
    properties = [String: [(String, String)]].init()
    transmissionTargetSelectorCell = loadCellFromNib()
    for targetName in (transmissionTargetSelectorCell?.transmissionTargets())! {
      properties[targetName] = [(String, String)].init()
    }
    transmissionTargetSelectorCell?.onTransmissionTargetSelected = transmissionTargetSelected
    tableView.setEditing(true, animated: false)
    self.enabled.isOn = appCenter.isAnalyticsEnabled()
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    var childTargetToken = UserDefaults.standard.string(forKey: kMSChildTransmissionTargetTokenKey)
    if childTargetToken != nil {
      let range = childTargetToken!.index(childTargetToken!.startIndex, offsetBy: 0)..<childTargetToken!.index(childTargetToken!.startIndex, offsetBy: 9)
      childTargetToken = childTargetToken![range]
    } else {
      childTargetToken = "None"
    }
    self.selectedChildTargetTokenLabel.text = "Child Target: " + childTargetToken!;
  }
  
  @IBAction func trackEvent() {
    guard let name = eventName.text else {
      return
    }
    let eventProperties = pairsToDictionary(pairs: properties[eventPropertiesIdentifier]!)
    appCenter.trackEvent(name, withProperties: eventProperties)
    if self.oneCollectorEnabled.isOn {
      let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
      let token = appName == "SasquatchSwift" ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken
      var target = MSAnalytics.transmissionTarget(forToken: token)
      let childTargetToken = UserDefaults.standard.string(forKey: kMSChildTransmissionTargetTokenKey)
      if childTargetToken != nil {
        target = target.transmissionTarget(forToken: childTargetToken!)
      }
      target.trackEvent(name, withProperties: eventProperties)
    }
  }
  
  @IBAction func trackPage() {
    guard let name = eventName.text else {
      return
    }
    let eventProperties = pairsToDictionary(pairs: properties[eventPropertiesIdentifier]!)
    appCenter.trackPage(name, withProperties: eventProperties)
  }

  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setAnalyticsEnabled(sender.isOn)
    sender.isOn = appCenter.isAnalyticsEnabled()
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
      properties[selectedTarget!]!.remove(at: indexPath.row - 2)
      tableView.deleteRows(at: [indexPath], with: .automatic)
    } else if editingStyle == .insert {
      let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
      let property = getNewDefaultProperty()
      properties[selectedTarget!]!.insert(property, at: 0)
      tableView.insertRows(at: [IndexPath(row: indexPath.row + 1, section: indexPath.section)], with: .automatic)
    }
  }
  
  func isInsertRow(at indexPath: IndexPath) -> Bool {
    return indexPath.section == kPropertiesSection && indexPath.row == 1
  }

  func isTargetSelectionRow(at indexPath: IndexPath) -> Bool {
    return indexPath.section == kPropertiesSection && indexPath.row == 0
  }

  func isPropertiesRowSection(_ section: Int) -> Bool {
    return section == kPropertiesSection
  }
  
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if isInsertRow(at: indexPath) {
      return .insert
    } else if isTargetSelectionRow(at: indexPath) {
      return .none
    }
    return .delete
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if isInsertRow(at: indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if isPropertiesRowSection(section) {
     return getPropertyCount() + 2
    } else {
      return super.tableView(tableView, numberOfRowsInSection: section)
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if isPropertiesRowSection(indexPath.section) {
      return super.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: indexPath.section))
    } else {
      return super.tableView(tableView, heightForRowAt: indexPath)
    }
  }

  override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
    if isPropertiesRowSection(indexPath.section) && !isTargetSelectionRow(at: indexPath) {
      return propertyIndentationLevel
    } else {
      return defaultIndentationLevel
    }
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return isPropertiesRowSection(indexPath.section) && !isTargetSelectionRow(at: indexPath)
  }
  
  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return false
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if isInsertRow(at: indexPath) {
      let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
      cell.textLabel?.text = "Add Property"
      return cell
    } else if isTargetSelectionRow(at: indexPath) {
      return transmissionTargetSelectorCell!
    } else if isPropertiesRowSection(indexPath.section) {
      let cell: MSAnalyticsPropertyTableViewCell? = loadCellFromNib()
      let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
      cell!.keyField.text = properties[selectedTarget!]![indexPath.row - 2].0
      cell!.valueField.text = properties[selectedTarget!]![indexPath.row - 2].1
      return cell!
    } else {
      return super.tableView(tableView, cellForRowAt: indexPath)
    }
  }

  func getPropertyCount() -> Int {
    let selectedTarget = transmissionTargetSelectorCell!.selectedTransmissionTarget()
    return (properties[selectedTarget!]!.count)
  }

  func loadCellFromNib<T: UITableViewCell>() -> T? {
    return Bundle.main.loadNibNamed(String(describing: T.self), owner: self, options: nil)?.first as? T
  }

  func getNewDefaultProperty() -> (String, String) {
    let keyValuePair = ("key\(propertyCounter)", "value\(propertyCounter)")
    propertyCounter += 1
    return keyValuePair
  }

  func pairsToDictionary(pairs: [(String, String)]) -> [String: String] {
    var propertyDictionary = [String: String].init()
    for pair in pairs {
      propertyDictionary[pair.0] = pair.1
    }
    return propertyDictionary
  }

  func transmissionTargetSelected() {
    NSLog("selected a target")
  }
}
