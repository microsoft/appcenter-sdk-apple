import UIKit

class MSDistributeViewController: UITableViewController, AppCenterProtocol {

  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var customized: UISwitch!
  var appCenter: AppCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.customized.isOn = UserDefaults.init().bool(forKey: kSASCustomizedUpdateAlertKey)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.enabled.isOn = appCenter.isDistributeEnabled()
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setDistributeEnabled(sender.isOn)
    sender.isOn = appCenter.isDistributeEnabled()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch (indexPath.section) {
      
    // Section with alerts.
    case 1:
      switch (indexPath.row) {
      case 0:
        if (!customized.isOn) {
          appCenter.showConfirmationAlert()
        } else {
          appCenter.showCustomConfirmationAlert()
        }
      case 1:
        appCenter.showDistributeDisabledAlert()
      default: ()
      }
    default: ()
    }
  }

  @IBAction func customizedSwitchUpdated(_ sender: UISwitch) {
    UserDefaults.init().set(sender.isOn ? true : false, forKey: kSASCustomizedUpdateAlertKey)
  }
}
