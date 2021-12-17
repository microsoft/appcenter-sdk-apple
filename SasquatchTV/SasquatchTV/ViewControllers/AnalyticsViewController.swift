// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit;

enum AnalyticsSections: Int { case analyticsSettings = 0; case trackEvent = 1; case trackPage = 2; case manualSessionTracker = 3; }

@objc open class AnalyticsViewController: UITableViewController, AppCenterProtocol {

  @IBOutlet weak var analyticsStatus: UILabel!
  @IBOutlet weak var manualSessionTrackerStatus: UILabel!
  
  @objc var appCenter: AppCenterDelegate!
  var properties : [String : String] = [String : String]();
  
  var isEnabled = true

  open override func viewDidLoad() {
        super.viewDidLoad()
    isEnabled = UserDefaults.standard.bool(forKey: kMSManualSessionTracker)
    manualSessionTrackerStatus?.text = isEnabled ? "Enabled" : "Disabled"
  }
  
  open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at : indexPath, animated : true)
    guard let section : AnalyticsSections = AnalyticsSections.init(rawValue : indexPath.section) else {
      return
    }
    switch (section) {
    case .analyticsSettings:
      appCenter.setAnalyticsEnabled(!appCenter.isAnalyticsEnabled())
      self.analyticsStatus.text = appCenter.isAnalyticsEnabled() ? "Enabled" : "Disabled"
    case .trackEvent:
      if indexPath.row == 0 {
        appCenter.trackEvent("tvOS Event", withProperties : properties);
      }
    case .trackPage:
      appCenter.trackPage("tvOS Page", withProperties : properties);
    case .manualSessionTracker:
      if indexPath.row == 0 {
        isEnabled = !isEnabled
        UserDefaults.standard.set(isEnabled , forKey: kMSManualSessionTracker);
        self.manualSessionTrackerStatus.text = isEnabled ? "Enabled" : "Disabled"
        print("Restart the app for the changes to take effect.")
      } else if indexPath.row == 1 {
        appCenter.startSession()
      }
    }
  }
}
