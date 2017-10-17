import UIKit

class MSPushViewController: UITableViewController, MobileCenterProtocol {

  @IBOutlet weak var enabled: UISwitch!
  var mobileCenter: MobileCenterDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.enabled.isOn = mobileCenter.isPushEnabled()
  }

  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    mobileCenter.setPushEnabled(sender.isOn)
    sender.isOn = mobileCenter.isPushEnabled()
  }
}
