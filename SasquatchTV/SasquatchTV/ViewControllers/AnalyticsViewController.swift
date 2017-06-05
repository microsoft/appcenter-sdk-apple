import UIKit

enum AnalyticsSections : Int {
  case actions = 0
  case settings = 1
}

enum AnalyticsActionsRows : Int {
  case trackEvent = 0
  case trackPage = 1
  case addProperty = 2
  case clearProperty = 3
}

class AnalyticsViewController: UITableViewController, MobileCenterProtocol {

  @IBOutlet weak var statusLabel: UILabel!

  var mobileCenter: MobileCenterDelegate!
  let properties : NSMutableDictionary = NSMutableDictionary();

  override func viewDidLoad() {
    super.viewDidLoad();
    self.statusLabel.text = mobileCenter.isAnalyticsEnabled() ? "Enabled" : "Disabled";
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true);
    guard let section : AnalyticsSections = AnalyticsSections.init(rawValue: indexPath.section) else {
      return;
    }
    switch(section) {
    case .actions:
      guard let action : AnalyticsActionsRows = AnalyticsActionsRows.init(rawValue: indexPath.row) else {
        return;
      }
      switch action {
      case .trackEvent:
        mobileCenter.trackPage("tvOS Event", withProperties: properties as! Dictionary<String, String>);
        break;
      case .trackPage:
        mobileCenter.trackPage("tvOS Page", withProperties: properties as! Dictionary<String, String>);
        break;
      case .addProperty:
        let propName : String = String(format: "Property name %d", properties.count + 1);
        let propValue : String = String(format: "Property value %d", properties.count + 1);
        properties.setValue(propName, forKey: propValue);
        break;
      case .clearProperty:
        properties.removeAllObjects();
        break;
      }
      break;
    case .settings:
      mobileCenter.setAnalyticsEnabled( !mobileCenter.isAnalyticsEnabled() );
      self.statusLabel.text = mobileCenter.isAnalyticsEnabled() ? "Enabled" : "Disabled";
      break;
    }
  }
}

