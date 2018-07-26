import UIKit

class MSAnalyticsViewController: UITableViewController, AppCenterProtocol {

  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var eventName: UITextField!
  @IBOutlet weak var pageName: UITextField!

  var appCenter: AppCenterDelegate!
  var eventPropertiesSection: EventPropertiesTableSection!
  @objc(analyticsResult) var analyticsResult: MSAnalyticsResult? = nil

  private var kEventPropertiesSectionIndex: Int = 2

  override func viewDidLoad() {
    eventPropertiesSection = EventPropertiesTableSection(tableSection: kEventPropertiesSectionIndex, tableView: tableView)
    super.viewDidLoad()
    tableView.setEditing(true, animated: false)
    
    // Disable results page.
    #if !ACTIVE_COMPILATION_CONDITION_PUPPET
    let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0))
    cell?.isUserInteractionEnabled = false
    cell?.contentView.alpha = 0.5
    #endif
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.enabled.isOn = appCenter.isAnalyticsEnabled()
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }

  @IBAction func trackEvent() {
    guard let name = eventName.text else {
      return
    }
    let eventPropertiesDictionary = eventPropertiesSection.eventPropertiesDictionary()
    if (MSTransmissionTargets.shared.defaultTargetShouldSendAnalyticsEvents()) {
      appCenter.trackEvent(name, withProperties: eventPropertiesDictionary)
    }
    for targetToken in MSTransmissionTargets.shared.transmissionTargets.keys {
      if MSTransmissionTargets.shared.targetShouldSendAnalyticsEvents(targetToken: targetToken) {
        let target = MSTransmissionTargets.shared.transmissionTargets[targetToken]
        target!.trackEvent(name, withProperties: eventPropertiesDictionary)
      }
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
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? MSAnalyticsResultViewController {
      destination.analyticsResult = analyticsResult
    }
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    eventPropertiesSection.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
  }

  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if indexPath.section == kEventPropertiesSectionIndex {
      return eventPropertiesSection.tableView(tableView, editingStyleForRowAt: indexPath)
    }
    return .delete
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if indexPath.section == kEventPropertiesSectionIndex && eventPropertiesSection.isInsertRow(indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == kEventPropertiesSectionIndex {
      return eventPropertiesSection.tableView(tableView, numberOfRowsInSection: section)
    }
    return super.tableView(tableView, numberOfRowsInSection: section)
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == kEventPropertiesSectionIndex {
      return super.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: indexPath.section))
    }
    return super.tableView(tableView, heightForRowAt: indexPath)
  }

  /**
   * Without this override, the default implementation will try to get a table cell that is out of bounds
   * (since they are inserted/removed at a slightly different time than the actual data source is updated).
   */
  override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
    return 0
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if indexPath.section == kEventPropertiesSectionIndex {
      return eventPropertiesSection.tableView(tableView, canEditRowAt:indexPath)
    }
    return false
  }

  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return false
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == kEventPropertiesSectionIndex {
      return eventPropertiesSection.tableView(tableView, cellForRowAt:indexPath)
    }
    return super.tableView(tableView, cellForRowAt: indexPath)
  }
}
