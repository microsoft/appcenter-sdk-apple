import UIKit

class MSDistributeViewController: UITableViewController, MobileCenterProtocol {

  let kCustomizedUpdateAlertKey = "kCustomizedUpdateAlertKey"

  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var customized: UISwitch!
  var mobileCenter: MobileCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.customized.isOn = UserDefaults.init().bool(forKey: kCustomizedUpdateAlertKey)
    self.enabled.isOn = mobileCenter.isDistributeEnabled()
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    mobileCenter.setDistributeEnabled(sender.isOn)
    sender.isOn = mobileCenter.isDistributeEnabled()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch (indexPath.section) {
      
    // Section with alerts.
    case 0:
      switch (indexPath.row) {
      case 0:
        if (!customized.isOn) {
          mobileCenter.showConfirmationAlert()
        } else {
          mobileCenter.showCustomConfirmationAlert()
        }
      case 1:
        mobileCenter.showDistributeDisabledAlert()
      default: ()
      }
    default: ()
    }
  }

  @IBAction func customizedSwitchUpdated(_ sender: UISwitch) {
    UserDefaults.init().set(sender.isOn ? true : false, forKey: kCustomizedUpdateAlertKey)
  }
}
