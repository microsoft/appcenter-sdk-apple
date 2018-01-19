import Cocoa

class LogFiltersViewController: NSViewController {

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!

  // Log type names.
  static let eventLogTypeName = "event"

  @IBOutlet weak var setEnabledButton: NSButton!
  @IBOutlet weak var setFilterEventLogsButton: NSButton!

  @IBAction func setEnabled(_ sender: NSButton) {
    appCenter.setLogFilterEnabled(sender.state == 1)
  }

  @IBAction func setFilterEventLogs(_ sender: NSButton) {
    updateFilterState(sender, LogFiltersViewController.eventLogTypeName)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setEnabledButton?.state = appCenter.isLogFilterEnabled() ? 1 : 0
    setFilterEventLogsButton?.state = appCenter.isFilteringLogType(LogFiltersViewController.eventLogTypeName) ? 1 : 0
  }

  func updateFilterState(_ sender: NSButton, _ logType: String) {
    if (sender.state == 1) {
      appCenter.filterLogType(logType)
    } else {
      appCenter.unfilterLogType(logType)
    }
  }
}
