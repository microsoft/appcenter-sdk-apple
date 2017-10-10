import UIKit

class MSMainViewController: UITableViewController, MobileCenterProtocol {
  
  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var installId: UILabel!
  @IBOutlet weak var appSecret: UILabel!
  @IBOutlet weak var logUrl: UILabel!
  @IBOutlet weak var sdkVersion: UILabel!
  var mobileCenter: MobileCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.enabled.isOn = mobileCenter.isMobileCenterEnabled()
    self.installId.text = mobileCenter.installId()
    self.appSecret.text = mobileCenter.appSecret()
    self.logUrl.text = mobileCenter.logUrl()
    self.sdkVersion.text = mobileCenter.sdkVersion()
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    mobileCenter.setMobileCenterEnabled(sender.isOn)
    sender.isOn = mobileCenter.isMobileCenterEnabled()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? MobileCenterProtocol{
      destination.mobileCenter = mobileCenter
    }
  }
}
