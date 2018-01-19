import Foundation

class LogFiltersViewController : UIViewController, AppCenterProtocol {

  var appCenter: AppCenterDelegate!

  // Log type names.
  static let eventLogTypeName = "event"

  // Toggle button titles.
  static let buttonTextEventFilteringOn = "Stop Filtering Event Logs"
  static let buttonTextEventFilteringOff = "Start Filtering Event Logs"

  @IBOutlet weak var enabledControl: UISegmentedControl!
  @IBOutlet weak var filterEventLogsButton: UIButton!
  
  @IBAction func setEnabled(_ sender: UISegmentedControl) {
    appCenter.setLogFilterEnabled(sender.selectedSegmentIndex == 0)
  }

  @IBAction func startFilteringEventLogs(_ sender: UIButton) {
    if (filterEventLogsButton.titleLabel!.text == LogFiltersViewController.buttonTextEventFilteringOn) {
      appCenter.unfilterLogType(LogFiltersViewController.eventLogTypeName)
    }
    else {
      appCenter.filterLogType(LogFiltersViewController.eventLogTypeName)
    }
    updateFilterButtonText()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    enabledControl.selectedSegmentIndex = appCenter.isLogFilterEnabled() ? 0 : 1
    updateFilterButtonText()
  }

  func updateFilterButtonText() {
    filterEventLogsButton.titleLabel!.text = appCenter.isFilteringLogType(LogFiltersViewController.eventLogTypeName) ? LogFiltersViewController.buttonTextEventFilteringOn : LogFiltersViewController.buttonTextEventFilteringOff
  }
}
