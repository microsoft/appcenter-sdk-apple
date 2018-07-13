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
  var eventPropertiesSection: EventPropertiesTableSection!
  var targetPropertiesSection: TargetPropertiesTableSection!

  override func viewDidLoad() {
    targetPropertiesSection = TargetPropertiesTableSection(tableSection: kTargetPropertiesSection, tableView: tableView)
    eventPropertiesSection = EventPropertiesTableSection(tableSection: kEventPropertiesSection, tableView: tableView)
    super.viewDidLoad()
    tableView.setEditing(true, animated: false)
    self.enabled.isOn = appCenter.isAnalyticsEnabled()
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
    let eventPropertiesDictionary = eventPropertiesSection.eventPropertiesDictionary()
    appCenter.trackEvent(name, withProperties: eventPropertiesDictionary)
    if self.oneCollectorEnabled.isOn {
      let targetToken = UserDefaults.standard.string(forKey: kMSChildTransmissionTargetTokenKey)
      let target = targetPropertiesSection.transmissionTarget(forTargetToken: targetToken!)
      target.trackEvent(name, withProperties: eventPropertiesDictionary)
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
    let propertySection = getPropertySection(at: indexPath)
    propertySection?.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
  }

  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if let propertySection = getPropertySection(at: indexPath) {
      return propertySection.tableView(tableView, editingStyleForRowAt: indexPath)
    }
    return .delete
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let propertySection = getPropertySection(at: indexPath)
    if propertySection != nil && propertySection!.isInsertRow(indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let propertySection = getPropertySection(at: IndexPath(row: 0, section: section)) {
      return propertySection.tableView(tableView, numberOfRowsInSection: section)
    }
    return super.tableView(tableView, numberOfRowsInSection: section)
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if getPropertySection(at: indexPath) != nil {
      return super.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: indexPath.section))
    }
    return super.tableView(tableView, heightForRowAt: indexPath)
  }

  override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
    return 0
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if let propertySection = getPropertySection(at: indexPath) {
      return propertySection.tableView(tableView, canEditRowAt:indexPath)
    }
    return false
  }

  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return false
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let propertySection = getPropertySection(at: indexPath) {
      return propertySection.tableView(tableView, cellForRowAt:indexPath)
    }
    return super.tableView(tableView, cellForRowAt: indexPath)
  }

  func getPropertySection(at indexPath: IndexPath) -> PropertiesTableSection? {
    if (eventPropertiesSection.hasSectionId(indexPath.section)) {
      return eventPropertiesSection
    } else if (targetPropertiesSection.hasSectionId(indexPath.section)) {
      return targetPropertiesSection
    }
    return nil
  }
}


