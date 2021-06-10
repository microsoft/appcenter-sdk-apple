// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit;

enum AppCenterSections: Int { case actions = 0; case miscellaneous = 1; case settings = 2; }

@objc open class AppCenterViewController : UITableViewController, AppCenterProtocol {

  @IBOutlet weak var installIdLabel : UILabel!
  @IBOutlet weak var appSecretLabel : UILabel!
  @IBOutlet weak var logURLLabel : UILabel!
  @IBOutlet weak var statusLabel : UILabel!
  @IBOutlet weak var networkRequestsLabel: UILabel!
  
  @objc var appCenter: AppCenterDelegate!

  open override func viewDidLoad() {
    super.viewDidLoad()
    self.installIdLabel.text = appCenter.installId()
    self.appSecretLabel.text = appCenter.appSecret()
    self.logURLLabel.text = appCenter.logUrl()
    self.statusLabel.text = appCenter.isAppCenterEnabled() ? "Enabled" : "Disabled"
    self.networkRequestsLabel.text = appCenter.isNetworkRequestsAllowed() ? "Allowed" : "Forbidden"
  }

  open override func tableView(_ tableView : UITableView, didSelectRowAt indexPath : IndexPath) {
    tableView.deselectRow(at : indexPath, animated : true)
    guard let section : AppCenterSections = AppCenterSections.init(rawValue : indexPath.section) else {
      return
      
    }
    switch (section) {
    case .miscellaneous:
      let isAllowed = !appCenter.isNetworkRequestsAllowed()
      appCenter.setNetworkRequestsAllowed(isAllowed)
      self.networkRequestsLabel.text = appCenter.isNetworkRequestsAllowed() ? "Allowed" : "Forbidden"
      break
    case.settings:
      appCenter.setAppCenterEnabled(!appCenter.isAppCenterEnabled())
      self.statusLabel.text = appCenter.isAppCenterEnabled() ? "Enabled" : "Disabled"
      break
    default:
      break
    }
  }

  open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? AppCenterProtocol {
      destination.appCenter = appCenter
    }
  }
}
