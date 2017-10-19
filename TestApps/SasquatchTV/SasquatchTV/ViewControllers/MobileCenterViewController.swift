import UIKit;

enum MobileCenterSections : Int { case actions = 0; case miscellaneous = 1; case settings = 2; }

@objc open class MobileCenterViewController : UITableViewController, MobileCenterProtocol {

  @IBOutlet weak var installIdLabel : UILabel!;
  @IBOutlet weak var appSecretLabel : UILabel!;
  @IBOutlet weak var logURLLabel : UILabel!;
  @IBOutlet weak var statusLabel : UILabel!;

  var mobileCenter : MobileCenterDelegate!;

  open override func viewDidLoad() {
    super.viewDidLoad();
    self.installIdLabel.text = mobileCenter.installId();
    self.appSecretLabel.text = mobileCenter.appSecret();
    self.logURLLabel.text = mobileCenter.logUrl();
    self.statusLabel.text = mobileCenter.isMobileCenterEnabled() ? "Enabled" : "Disabled";
  }

  open override func tableView(_ tableView : UITableView, didSelectRowAt indexPath : IndexPath) {
    tableView.deselectRow(at : indexPath, animated : true);
    guard let section : MobileCenterSections = MobileCenterSections.init(rawValue : indexPath.section) else { return; }
    switch (section) {
    case.settings:
      mobileCenter.setMobileCenterEnabled(!mobileCenter.isMobileCenterEnabled());
      self.statusLabel.text = mobileCenter.isMobileCenterEnabled() ? "Enabled" : "Disabled";
      break;
    default:
      break;
    }
  }

  open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? MobileCenterProtocol {
      destination.mobileCenter = mobileCenter;
    }
  }
}
