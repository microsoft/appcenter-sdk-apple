import UIKit

class MSAnalyticsViewController: UITableViewController, AppCenterProtocol {
  
  @IBOutlet weak var propertiesTable: UITableView!
  @IBOutlet weak var enabled: UISwitch!
  var appCenter: AppCenterDelegate!
  var propertiesSource: MSPropertiesTableDataSource?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.enabled.isOn = appCenter.isAnalyticsEnabled()
    propertiesSource = MSPropertiesTableDataSource.init(table: propertiesTable)
  }

  @IBAction func onAddProperty() {
    propertiesSource?.addNewProperty()
  }

  @IBAction func onDeleteProperty() {
    propertiesSource?.deleteProperty()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    propertiesSource?.updateProperties()
    switch indexPath.section {
    case 1:
      switch indexPath.row {
      case 0:
        appCenter.trackEvent("myEvent", withProperties: propertiesSource?.properties() as! Dictionary<String, String>)
      case 1:
        appCenter.trackPage("myPage", withProperties: propertiesSource?.properties() as! Dictionary<String, String>)
      default: ()
      }
      break
    default: ()
    }
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setAnalyticsEnabled(sender.isOn)
    sender.isOn = appCenter.isAnalyticsEnabled()
  }
}
