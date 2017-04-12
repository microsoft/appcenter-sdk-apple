import UIKit

class MSDistributeViewController: UITableViewController, MobileCenterProtocol {
  
  @IBOutlet weak var enabled: UISwitch!
  var mobileCenter: MobileCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
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
        mobileCenter.showConfirmationAlert()
      case 1:
        mobileCenter.showDistributeDisabledAlert()
      default: ()
      }
    default: ()
    }
  }
}
