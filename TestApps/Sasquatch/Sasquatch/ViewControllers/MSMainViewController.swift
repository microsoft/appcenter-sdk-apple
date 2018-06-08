import UIKit

class MSMainViewController: UITableViewController, AppCenterProtocol {
  
  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var oneCollectorEnabled: UISwitch!
  @IBOutlet weak var installId: UILabel!
  @IBOutlet weak var appSecret: UILabel!
  @IBOutlet weak var logUrl: UILabel!
  @IBOutlet weak var sdkVersion: UILabel!
  var appCenter: AppCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.enabled.isOn = appCenter.isAppCenterEnabled()
    self.oneCollectorEnabled.isOn = UserDefaults.standard.bool(forKey: "isOneCollectorEnabled")
    self.installId.text = appCenter.installId()
    self.appSecret.text = appCenter.appSecret()
    self.logUrl.text = appCenter.logUrl()
    self.sdkVersion.text = appCenter.sdkVersion()
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setAppCenterEnabled(sender.isOn)
    sender.isOn = appCenter.isAppCenterEnabled()
  }
  
  @IBAction func enableOneCollectorSwitchUpdated(_ sender: UISwitch) {
    let alert = UIAlertController(title: "Restart", message: "Please restart the app for the change to take effect.",
                                  preferredStyle: .actionSheet)
    let exitAction = UIAlertAction(title: "Exit", style: .destructive) {_ in
      UserDefaults.standard.set(sender.isOn, forKey: "isOneCollectorEnabled")
      exit(0)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {_ in
      sender.isOn = UserDefaults.standard.bool(forKey: "isOneCollectorEnabled")
      alert.dismiss(animated: true, completion: nil)
    }
    alert.addAction(exitAction)
    alert.addAction(cancelAction)
    self.present(alert, animated: true, completion: nil)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? AppCenterProtocol {
      destination.appCenter = appCenter
    }
  }
}
