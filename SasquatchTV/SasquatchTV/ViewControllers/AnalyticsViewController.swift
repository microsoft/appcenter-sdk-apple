import UIKit;

enum AnalyticsSections : Int { case actions = 0; case settings = 1; }

enum AnalyticsActionsRows : Int {
  case trackEvent = 0; case trackPage = 1; case addProperty = 2; case clearProperty = 3;
}

class AnalyticsViewController : UIViewController, UITableViewDataSource, AppCenterProtocol {

  @IBOutlet weak var serviceStatus : UISegmentedControl?;
  @IBOutlet weak var table : UITableView?;

  var appCenter : AppCenterDelegate!;
  var properties : [String : String] = [String : String]();

  override func viewDidLoad() {
    super.viewDidLoad();
    table?.dataSource = self;
    table?.allowsSelection = true;
    serviceStatus?.selectedSegmentIndex = appCenter.isAnalyticsEnabled() ? 0 : 1;
    serviceStatus?.addTarget(self, action: #selector(self.switchAnalyticsStatus), for: .valueChanged);
  }

  @IBAction func trackEvent(_ : Any) {
    appCenter.trackEvent("tvOS Event", withProperties : properties);
  }

  @IBAction func trackPage(_ : Any) {
    appCenter.trackPage("tvOS Page", withProperties : properties);
  }

  @IBAction func addProperty(_ : Any) {
    let propKey : String = String(format : "key%d", properties.count + 1);
    let propValue : String = String(format : "value%d", properties.count + 1);
    properties.updateValue(propValue, forKey: propKey);
    table?.reloadData();
  }

  @IBAction func deleteProperty(_ : Any) {
    properties.removeAll();
    table?.reloadData();
  }

  func switchAnalyticsStatus(_ : Any) {
    appCenter.setAnalyticsEnabled(serviceStatus?.selectedSegmentIndex == 0);
    serviceStatus?.selectedSegmentIndex = appCenter.isAnalyticsEnabled() ? 0 : 1;
  }

  //MARK: Table view data source

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return properties.count;
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell : MSPropertyViewCell = tableView.dequeueReusableCell(withIdentifier: "propertyViewCell", for: indexPath) as? MSPropertyViewCell else {
      return UITableViewCell();
    }
    let propKey : String = Array(properties.keys)[indexPath.row];
    cell.propertyKey?.text = propKey;
    cell.propertyValue?.text = properties[propKey];
    return cell;
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard let editPropertyViewController = segue.destination as? EditPropertyViewController else {
      return;
    }
    guard let indexPath = table?.indexPathForSelectedRow else {
      return;
    }

    let key : String = Array(properties.keys)[indexPath.row];
    let value : String = properties[key] ?? "";

    editPropertyViewController.oldKey = key;
    editPropertyViewController.oldValue = value;
    editPropertyViewController.properties = properties;
    editPropertyViewController.appCenter = appCenter;
  }
}
