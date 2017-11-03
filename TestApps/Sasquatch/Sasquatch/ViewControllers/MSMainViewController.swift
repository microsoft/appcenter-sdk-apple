import UIKit

class MSMainViewController: UITableViewController, AppCenterProtocol {
  
  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var installId: UILabel!
  @IBOutlet weak var appSecret: UILabel!
  @IBOutlet weak var logUrl: UILabel!
  @IBOutlet weak var sdkVersion: UILabel!
  var appCenter: AppCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.enabled.isOn = appCenter.isAppCenterEnabled()
    self.installId.text = appCenter.installId()
    self.appSecret.text = appCenter.appSecret()
    self.logUrl.text = appCenter.logUrl()
    self.sdkVersion.text = appCenter.sdkVersion()
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setAppCenterEnabled(sender.isOn)
    sender.isOn = appCenter.isAppCenterEnabled()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? AppCenterProtocol{
      destination.appCenter = appCenter
    }
  }
}
