import UIKit
import AppCenterPush

class MSMainViewController: UITableViewController, AppCenterProtocol {
  
  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var oneCollectorEnabled: UISwitch!
  @IBOutlet weak var installId: UILabel!
  @IBOutlet weak var appSecret: UILabel!
  @IBOutlet weak var logUrl: UILabel!
  @IBOutlet weak var sdkVersion: UILabel!
  @IBOutlet weak var startTarget: UISegmentedControl!

  @IBOutlet weak var pushEnabledSwitch: UISwitch!
  var appCenter: AppCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.enabled.isOn = appCenter.isAppCenterEnabled()
    //self.oneCollectorEnabled.isOn = UserDefaults.standard.bool(forKey: "isOneCollectorEnabled")
    self.installId.text = appCenter.installId()
    self.appSecret.text = appCenter.appSecret()
    self.logUrl.text = appCenter.logUrl()
    self.sdkVersion.text = appCenter.sdkVersion()
    self.startTarget.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "startTarget")
    pushEnabledSwitch.isOn = MSPush.isEnabled()
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setAppCenterEnabled(sender.isOn)
    sender.isOn = appCenter.isAppCenterEnabled()
  }
  
  @IBAction func pushSwitchStateUpdated(_ sender: UISwitch) {
    MSPush.setEnabled(sender.isOn)
    sender.isOn = MSPush.isEnabled()
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
    
    // Support display in iPad.
    alert.popoverPresentationController?.sourceView = self.oneCollectorEnabled.superview;
    alert.popoverPresentationController?.sourceRect = self.oneCollectorEnabled.frame;
    self.present(alert, animated: true, completion: nil)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? AppCenterProtocol {
      destination.appCenter = appCenter
    }
  }
  
  @IBAction func selectTarget(_ sender: UISegmentedControl) {
    let alert = UIAlertController(title: "Restart", message: "Please restart the app for the change to take effect.",
                                  preferredStyle: .actionSheet)
    let exitAction = UIAlertAction(title: "Exit", style: .destructive) {_ in
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: "startTarget")
        exit(0)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {_ in
        sender.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "startTarget")
        alert.dismiss(animated: true, completion: nil)
    }
    alert.addAction(exitAction)
    alert.addAction(cancelAction)
    
    // Support display in iPad.
    alert.popoverPresentationController?.sourceView = self.oneCollectorEnabled.superview;
    alert.popoverPresentationController?.sourceRect = self.oneCollectorEnabled.frame;
    self.present(alert, animated: true, completion: nil)
  }
}
