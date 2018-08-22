import UIKit

class MSAnalyticsChildTransmissionTargetTableViewController: UITableViewController, AppCenterProtocol {
  @IBOutlet weak var childToken1Label: UILabel!
  @IBOutlet weak var childToken2Label: UILabel!
  
  var appCenter: AppCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.childToken1Label.text = "Child Target Token 1 - 602c2d52"
    self.childToken2Label.text = "Child Target Token 2 - 902923eb"
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }
  
  // MARK: - Table view data source
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.row {
    case 0:
      UserDefaults.standard.setValue(nil, forKey: kMSChildTransmissionTargetTokenKey)
      self.navigationController?.popViewController(animated: true)
      break
    case 1:
      UserDefaults.standard.setValue(kMSTargetToken1, forKey: kMSChildTransmissionTargetTokenKey)
      self.navigationController?.popViewController(animated: true)
      break
    case 2:
      UserDefaults.standard.setValue(kMSTargetToken2, forKey: kMSChildTransmissionTargetTokenKey)
      self.navigationController?.popViewController(animated: true)
    default:
      break
    }
  }
}
