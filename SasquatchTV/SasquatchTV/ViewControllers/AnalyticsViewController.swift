// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit;

enum AnalyticsSections: Int { case settings = 0; case trackEvent = 1; case trackPage = 2; case manualSessionTracker = 3; }

@objc open class AnalyticsViewController: UITableViewController, AppCenterProtocol {

  @IBOutlet weak var analyticsStatus: UILabel!
  @IBOutlet weak var manualSessionTrackerStatus: UILabel!
  
  var appCenter: AppCenterDelegate!
  var properties : [String : String] = [String : String]();
  
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
    case .trackEvent:
        appCenter.trackEvent("tvOS Event", withProperties : properties);
    case .trackPage:
      appCenter.trackPage("tvOS Page", withProperties : properties);
    case .manualSessionTracker:
      if indexPath.row == 0 {
        isManualSessionTrackerEnabled = !isManualSessionTrackerEnabled
        UserDefaults.standard.set(isManualSessionTrackerEnabled , forKey: kMSManualSessionTracker);
        self.manualSessionTrackerStatus.text = isManualSessionTrackerEnabled ? "Enabled" : "Disabled"
        print("Restart the app for the changes to take effect.")
      } else if indexPath.row == 1 {
        appCenter.startSession()
      }
    }
  }
}
