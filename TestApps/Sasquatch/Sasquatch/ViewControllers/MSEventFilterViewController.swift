import UIKit

class MSEventFilterViewController: UITableViewController, UINavigationControllerDelegate, AppCenterProtocol {
  var appCenter: AppCenterDelegate!

  @IBOutlet weak var enabled: UISwitch!

  override func viewDidLoad() {
    appCenter.startEventFilterService()
    self.enabled.isOn = appCenter.isEventFilterEnabled()
  }

  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setEventFilterEnabled(sender.isOn)
    sender.isOn = appCenter.isEventFilterEnabled()
  }
}

