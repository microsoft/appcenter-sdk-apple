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
}
