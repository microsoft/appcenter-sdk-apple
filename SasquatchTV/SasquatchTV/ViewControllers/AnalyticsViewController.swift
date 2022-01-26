// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit;

enum AnalyticsSections: Int { case settings = 0; case trackEvent = 1; case trackPage = 2; case manualSessionTracker = 3; }

@objc open class AnalyticsViewController: UITableViewController, AppCenterProtocol {

  @IBOutlet weak var analyticsStatus: UILabel!
  @IBOutlet weak var manualSessionTrackerStatus: UILabel!
  
  var appCenter: AppCenterDelegate!
  
  var isManualSessionTrackerEnabled = true

  open override func viewDidLoad() {
    super.viewDidLoad()
    isManualSessionTrackerEnabled = UserDefaults.standard.bool(forKey: kMSManualSessionTracker)
    manualSessionTrackerStatus.text = isManualSessionTrackerEnabled ? "Enabled" : "Disabled"
  }
  
  open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let section = AnalyticsSections.init(rawValue : indexPath.section) else {
      return
    }
    switch (section) {
    case .settings:
      appCenter.setAnalyticsEnabled(!appCenter.isAnalyticsEnabled())
      self.analyticsStatus.text = appCenter.isAnalyticsEnabled() ? "Enabled" : "Disabled"
      break
    case .trackEvent:
      if indexPath.row == 0 {
        appCenter.trackEvent("tvOS event")
      } else if indexPath.row == 1 {
        appCenter.trackEvent("tvOS event with properties", withProperties: ["key1" : "value1", "key2": "value2"])
      }
      break
    case .trackPage:
      appCenter.trackPage("tvOS page")
      break
    case .manualSessionTracker:
      if indexPath.row == 0 {
        isManualSessionTrackerEnabled = !isManualSessionTrackerEnabled
        UserDefaults.standard.set(isManualSessionTrackerEnabled , forKey: kMSManualSessionTracker);
        self.manualSessionTrackerStatus.text = isManualSessionTrackerEnabled ? "Enabled" : "Disabled"
        print("Restart the app for the changes to take effect.")
      } else if indexPath.row == 1 {
        appCenter.startSession()
      }
      break
    }
  }
}
