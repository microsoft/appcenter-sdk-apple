import UIKit

private var kEventPropertiesSection: Int = 2
private var kTargetPropertiesSection: Int = 3

class MSAnalyticsViewController: UITableViewController, AppCenterProtocol {
  
  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var oneCollectorEnabled: UISwitch!
  @IBOutlet weak var eventName: UITextField!
  @IBOutlet weak var pageName: UITextField!
  @IBOutlet weak var selectedChildTargetTokenLabel: UILabel!

  var appCenter: AppCenterDelegate!
  var targetProperties: [String: [(String, String)]]!
  var eventProperties: [(String, String)]!
  var transmissionTargets: [String: MSAnalyticsTransmissionTarget]!
  var transmissionTargetSelectorCell: MSAnalyticsTranmissionTargetSelectorViewCell?
  var propertyCounter = 0

  override func viewDidLoad() {
    eventProperties = [(String, String)]()
    transmissionTargetSelectorCell = loadCellFromNib()
    transmissionTargetSelectorCell?.didSelectTransmissionTarget = didSelectTransmissionTarget
    tableView.setEditing(true, animated: false)
    self.enabled.isOn = appCenter.isAnalyticsEnabled()

    // Set up all transmission targets and associated mappings. The three targets and their tokens are hard coded.
    transmissionTargets = [String: MSAnalyticsTransmissionTarget]()
    targetProperties = [String: [(String, String)]]()

    // Parent target.
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    let parentTargetToken = appName == "SasquatchSwift" ? kMSSwiftRuntimeTargetToken : kMSObjCRuntimeTargetToken
    let parentTarget = MSAnalytics.transmissionTarget(forToken: parentTargetToken)
    transmissionTargets[parentTargetToken] = parentTarget
    targetProperties[parentTargetToken] = [(String, String)]()

    // Child 1 target.
    let childTarget1 = MSAnalytics.transmissionTarget(forToken: kMSTargetToken1)
    transmissionTargets[kMSTargetToken1] = childTarget1
    targetProperties[kMSTargetToken1] = [(String, String)]()

    // Child 2 target.
    let childTarget2 = MSAnalytics.transmissionTarget(forToken: kMSTargetToken2)
    transmissionTargets[kMSTargetToken2] = childTarget2
    targetProperties[kMSTargetToken2] = [(String, String)]()
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
    let eventPropertiesDictionary = pairsToDictionary(pairs: eventProperties)
    appCenter.trackEvent(name, withProperties: eventPropertiesDictionary)
    if self.oneCollectorEnabled.isOn {
      let targetToken = UserDefaults.standard.string(forKey: kMSChildTransmissionTargetTokenKey)
      transmissionTargets[targetToken!]!.trackEvent(name, withProperties: eventPropertiesDictionary)
    }
  }
  
  @IBAction func trackPage() {
    guard let name = eventName.text else {
      return
    }
    appCenter.trackPage(name)
  }

  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setAnalyticsEnabled(sender.isOn)
    sender.isOn = appCenter.isAnalyticsEnabled()
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if (isTargetPropertiesRowSection(indexPath.section)) {
      if editingStyle == .delete {
        let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
        let key = targetProperties[selectedTarget!]![indexPath.row - 2].0
        let target = MSAnalytics.transmissionTarget(forToken: selectedTarget!)
        target.removeEventPropertyforKey(key)
        targetProperties[selectedTarget!]!.remove(at: indexPath.row - 2)
        tableView.deleteRows(at: [indexPath], with: .automatic)
      } else if editingStyle == .insert {
        let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
        let property = getNewDefaultProperty()
        targetProperties[selectedTarget!]!.insert(property, at: 0)
        let target = MSAnalytics.transmissionTarget(forToken: selectedTarget!)
        target.setEventPropertyString(property.0, forKey: property.1)
        tableView.insertRows(at: [IndexPath(row: indexPath.row + 1, section: indexPath.section)], with: .automatic)
      }
    } else if (isEventPropertiesRowSection(indexPath.section)) {
      if editingStyle == .delete {
        eventProperties!.remove(at: indexPath.row - 1)
        tableView.deleteRows(at: [indexPath], with: .automatic)
      } else if editingStyle == .insert {
        let property = getNewDefaultProperty()
        eventProperties!.insert(property, at: 0)
        tableView.insertRows(at: [IndexPath(row: indexPath.row + 1, section: indexPath.section)], with: .automatic)
      }
    }
  }
  
  func isInsertRow(at indexPath: IndexPath) -> Bool {
    return (indexPath.section == kEventPropertiesSection && indexPath.row == 0) ||
    (indexPath.section == kTargetPropertiesSection && indexPath.row == 1)
  }

  func isTargetSelectionRow(at indexPath: IndexPath) -> Bool {
    return indexPath.section == kTargetPropertiesSection && indexPath.row == 0
  }

  func isEventPropertiesRowSection(_ section: Int) -> Bool {
    return section == kEventPropertiesSection
  }

  func isTargetPropertiesRowSection(_ section: Int) -> Bool {
    return section == kTargetPropertiesSection
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
    if isTargetPropertiesRowSection(section) {
     return getTargetPropertyCount() + 2
    } else if isEventPropertiesRowSection(section) {
      return getEventPropertyCount() + 1
    } else {
      return super.tableView(tableView, numberOfRowsInSection: section)
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if isEventPropertiesRowSection(indexPath.section) || isTargetPropertiesRowSection(indexPath.section) {
      return super.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: indexPath.section))
    } else {
      return super.tableView(tableView, heightForRowAt: indexPath)
    }
  }

  override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
    return 0
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return isEventPropertiesRowSection(indexPath.section) || isTargetPropertiesRowSection(indexPath.section)
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
    } else if isTargetPropertiesRowSection(indexPath.section) {
      let cell: MSAnalyticsPropertyTableViewCell? = loadCellFromNib()
      let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
      cell!.keyField.text = targetProperties[selectedTarget!]![indexPath.row - 2].0
      cell!.valueField.text = targetProperties[selectedTarget!]![indexPath.row - 2].1

      // Set the tag to the array index so the callback can identify which property to change when the fields are edited.
      cell!.keyField.tag = targetProperties![selectedTarget!]!.count - 1
      cell!.valueField.tag = targetProperties![selectedTarget!]!.count - 1
      cell!.keyField.addTarget(self, action: #selector(targetPropertyKeyChanged), for: .editingChanged)
      cell!.valueField.addTarget(self, action: #selector(targetPropertyValueChanged), for: .editingChanged)
      return cell!
    } else if isEventPropertiesRowSection(indexPath.section) {
      let cell: MSAnalyticsPropertyTableViewCell? = loadCellFromNib()
      cell!.keyField.text = eventProperties[indexPath.row - 1].0
      cell!.valueField.text = eventProperties[indexPath.row - 1].1

      // Set the tag to the array index so the callback can identify which property to change when the fields are edited.
      cell!.keyField.tag = eventProperties.count - 1
      cell!.valueField.tag = eventProperties.count - 1
      cell!.keyField.addTarget(self, action: #selector(eventArgumentPropertyKeyChanged), for: .editingChanged)
      cell!.valueField.addTarget(self, action: #selector(eventArgumentPropertyValueChanged), for: .editingChanged)
      return cell!
    } else {
      return super.tableView(tableView, cellForRowAt: indexPath)
    }
  }

  func eventArgumentPropertyKeyChanged(sender: UITextField!) {
    let arrayIndex = sender!.tag
    eventProperties[arrayIndex].0 = sender.text!
  }

  func eventArgumentPropertyValueChanged(sender: UITextField!) {
    let arrayIndex = sender!.tag
    eventProperties[arrayIndex].1 = sender.text!
  }

  func targetPropertyKeyChanged(sender: UITextField!) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let arrayIndex = sender!.tag
    let currentPropertyKey = targetProperties[selectedTarget!]![arrayIndex].0
    let currentPropertyValue = targetProperties[selectedTarget!]![arrayIndex].1
    let target = MSAnalytics.transmissionTarget(forToken: selectedTarget!)
    target.removeEventPropertyforKey(currentPropertyKey)
    target.setEventPropertyString(currentPropertyValue, forKey: sender.text!)
    targetProperties[selectedTarget!]![arrayIndex].0 = sender.text!
  }

  func targetPropertyValueChanged(sender: UITextField!) {
    let selectedTarget = transmissionTargetSelectorCell?.selectedTransmissionTarget()
    let arrayIndex = sender!.tag
    let currentPropertyKey = targetProperties[selectedTarget!]![arrayIndex].0
    let target = MSAnalytics.transmissionTarget(forToken: selectedTarget!)
    target.setEventPropertyString(sender.text!, forKey: currentPropertyKey)
    targetProperties[selectedTarget!]![arrayIndex].1 = sender.text!
  }

  func getTargetPropertyCount() -> Int {
    let selectedTarget = transmissionTargetSelectorCell!.selectedTransmissionTarget()
    return (targetProperties[selectedTarget!]!.count)
  }

  func getEventPropertyCount() -> Int {
    return eventProperties!.count
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

  func didSelectTransmissionTarget() {
    tableView.reloadData()
  }
}
