import UIKit

class MSPushViewController: UITableViewController, AppCenterProtocol {

  @IBOutlet weak var enabled: UISwitch!
  var appCenter: AppCenterDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.enabled.isOn = appCenter.isPushEnabled()
  }

  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setPushEnabled(sender.isOn)
    sender.isOn = appCenter.isPushEnabled()
  }
}
