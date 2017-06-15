import UIKit

class MSAnalyticsViewController: UITableViewController, MobileCenterProtocol {
  
  @IBOutlet weak var propertiesTable: UITableView!
  @IBOutlet weak var enabled: UISwitch!
  var mobileCenter: MobileCenterDelegate!
  var propertiesSource: MSPropertiesTableDataSource?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.enabled.isOn = mobileCenter.isAnalyticsEnabled()
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
        mobileCenter.trackEvent("myEvent")
      case 1:
        mobileCenter.trackEvent("myEvent", withProperties: propertiesSource?.properties() as! Dictionary<String, String>)
      case 2:
        mobileCenter.trackPage("myPage")
      case 3:
        mobileCenter.trackPage("myPage", withProperties: propertiesSource?.properties() as! Dictionary<String, String>)
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
