import UIKit

class MSAnalyticsViewController: UITableViewController, MobileCenterProtocol {
  
  @IBOutlet weak var enabled: UISwitch!
  var mobileCenter: MobileCenterDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.enabled.isOn = mobileCenter.isAnalyticsEnabled()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.section {
    case 0:
      switch indexPath.row {
      case 0:
        mobileCenter.trackEvent("myEvent")
      case 1:
        mobileCenter.trackEvent("myEvent", withProperties: ["gender" : "Male", "age" : "20", "title" : "SDE"])
      case 2:
        mobileCenter.trackPage("myPage")
      case 3:
        mobileCenter.trackPage("myPage", withProperties: ["gender" : "Male", "age" : "28", "title" : "PM"])
      default: ()
      }
      break
    default: ()
    }
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    mobileCenter.setAnalyticsEnabled(sender.isOn)
    sender.isOn = mobileCenter.isAnalyticsEnabled()
  }
}
