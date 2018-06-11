import UIKit

private var kPropertiesSection: Int = 3

class MSAnalyticsViewController: UITableViewController, AppCenterProtocol {
  
  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var oneCollectorEnabled: UISwitch!
  @IBOutlet weak var eventName: UITextField!
  @IBOutlet weak var pageName: UITextField!
  var appCenter: AppCenterDelegate!
  var propertiesCount: Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.setEditing(true, animated: false)
    self.enabled.isOn = appCenter.isAnalyticsEnabled()
  }
  
  @IBAction func trackEvent() {
    guard let name = eventName.text else {
      return
    }
    if self.oneCollectorEnabled.isOn {
      let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
      let token = appName == "SasquatchSwift" ? "238db5abfbaa4c299b78dd539f78b829-cd10afb7-0ec2-496f-ac8a-c21974fbb82c-7564" : "1aa046cfdc8f49bdbd64190290caf7dd-ba041023-af4d-4432-a87e-eb2431150797-7361"
      MSAnalytics.transmissionTarget(forToken: token).trackEvent(name, withProperties: properties())
    } else {
      appCenter.trackEvent(name, withProperties: properties())
    }
  }
  
  @IBAction func trackPage() {
    guard let name = eventName.text else {
      return
    }
    appCenter.trackPage(name, withProperties: properties())
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setAnalyticsEnabled(sender.isOn)
    sender.isOn = appCenter.isAnalyticsEnabled()
  }
  
  func properties() -> [String: String] {
    var properties = [String: String]()
    for i in 0..<propertiesCount {
      guard let cell = tableView.cellForRow(at: IndexPath(row: i, section: kPropertiesSection)) as? MSAnalyticsPropertyTableViewCell else {
        continue
      }
      guard let key = cell.keyField.text,
            let value = cell.valueField.text else {
        continue
      }
      properties[key] = value
    }
    return properties
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      propertiesCount -= 1
      tableView.deleteRows(at: [indexPath], with: .automatic)
    } else if editingStyle == .insert {
      propertiesCount += 1
      tableView.insertRows(at: [indexPath], with: .automatic)
    }
  }
  
  func isInsertRow(at indexPath: IndexPath) -> Bool {
    return indexPath.section == kPropertiesSection && indexPath.row == tableView(tableView, numberOfRowsInSection: indexPath.section) - 1
  }
  
  func isPropertiesRowSection(_ section: Int) -> Bool {
    return section == kPropertiesSection
  }
  
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if isInsertRow(at: indexPath) {
      return .insert
    } else {
      return .delete
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if isInsertRow(at: indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if isPropertiesRowSection(section) {
      return propertiesCount + 1
    } else {
      return super.tableView(tableView, numberOfRowsInSection: section)
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if isPropertiesRowSection(indexPath.section) {
      return super.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: indexPath.section))
    } else {
      return super.tableView(tableView, heightForRowAt: indexPath)
    }
  }

  override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
    if isPropertiesRowSection(indexPath.section) {
      return super.tableView(tableView, indentationLevelForRowAt: IndexPath(row: 0, section: indexPath.section))
    } else {
      return super.tableView(tableView, indentationLevelForRowAt: indexPath)
    }
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return isPropertiesRowSection(indexPath.section)
  }
  
  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return false
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if isInsertRow(at: indexPath) {
      let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
      cell.textLabel?.text = "Add Property"
      return cell
    } else if isPropertiesRowSection(indexPath.section) {
      return Bundle.main.loadNibNamed("MSAnalyticsPropertyTableViewCell", owner: self, options: nil)?.first as? UITableViewCell ?? UITableViewCell()
    } else {
      return super.tableView(tableView, cellForRowAt: indexPath)
    }
  }
}
