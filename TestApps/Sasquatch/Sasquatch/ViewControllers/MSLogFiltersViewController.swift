import UIKit


class MSLogFiltersViewController: UITableViewController, UINavigationControllerDelegate, AppCenterProtocol {
  var appCenter: AppCenterDelegate!

  // Log types. Only possible to filter event logs for now, but it is relatively simple to add other types.
  static let eventLogTypeName = "event"

  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var eventLogFilteringEnabled: UISwitch!

  override func viewDidLoad() {
    self.enabled.isOn = appCenter.isLogFilterEnabled()
    self.eventLogFilteringEnabled.isOn = appCenter.isFilteringLogType(MSLogFiltersViewController.eventLogTypeName)
  }

  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setLogFilterEnabled(sender.isOn)
    sender.isOn = appCenter.isLogFilterEnabled()
  }

  @IBAction func eventLogFilteringEnabledSwitchUpdated(_ sender: UISwitch) {
    updateFilterState(sender, MSLogFiltersViewController.eventLogTypeName)
  }

  func updateFilterState(_ sender: UISwitch, _ logType: String) {
    if (sender.isOn) {
      appCenter.filterLogType(logType)
    } else {
      appCenter.unfilterLogType(logType)
    }
  }
}

