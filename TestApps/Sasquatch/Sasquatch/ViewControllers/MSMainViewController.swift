import UIKit

class MSMainViewController: UITableViewController, AppCenterProtocol {
  
  @IBOutlet weak var appCenterEnabledSwitch: UISwitch!
  @IBOutlet weak var oneCollectorEnabledLabel: UILabel!
  @IBOutlet weak var oneCollectorEnabledSwitch: UISwitch!
  @IBOutlet weak var installId: UILabel!
  @IBOutlet weak var appSecret: UILabel!
  @IBOutlet weak var logUrl: UILabel!
  @IBOutlet weak var sdkVersion: UILabel!
  @IBOutlet weak var pushEnabledSwitch: UISwitch!

  var appCenter: AppCenterDelegate!

  static let kStartupTypeSectionIndex = 2
  var appTargetCellIndexPath = IndexPath(row:0, section:kStartupTypeSectionIndex)
  var libraryTargetCellIndexPath = IndexPath(row:1, section:kStartupTypeSectionIndex)
  var bothTargetsCellIndexPath = IndexPath(row: 2, section: kStartupTypeSectionIndex)
  var informationCellIndexPath = IndexPath(row: 3, section: kStartupTypeSectionIndex)

  override func viewDidLoad() {
    super.viewDidLoad()
    appCenterEnabledSwitch.isOn = appCenter.isAppCenterEnabled()

    // One Collector section.
    let oneCollectorEnabled = UserDefaults.standard.bool(forKey: kMSOneCollectorEnabledKey)
    oneCollectorEnabledSwitch.isOn = oneCollectorEnabled
    oneCollectorEnabledLabel.text = oneCollectorEnabled ? "Enabled" : "Disabled"

    // Startup Targets section.
    let startupTypeCellIndexPath = MSMainViewController.getIndexPathForSelectedStartupTypeCell()
    toggleSelectionForCellAtIndexPath(startupTypeCellIndexPath)
    let selectedCell = self.tableView(tableView, cellForRowAt: startupTypeCellIndexPath)
    let informationCell = self.tableView(tableView, cellForRowAt: informationCellIndexPath)
    for subview in selectedCell.contentView.subviews {
      if let label = subview as? UILabel {
        informationCell.detailTextLabel!.text = label.text
        break
      }
    }

    // Miscellaneous section.
    pushEnabledSwitch.isOn = appCenter.isPushEnabled()
    self.installId.text = appCenter.installId()
    self.appSecret.text = appCenter.appSecret()
    self.logUrl.text = appCenter.logUrl()
    self.sdkVersion.text = appCenter.sdkVersion()
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setAppCenterEnabled(sender.isOn)
    sender.isOn = appCenter.isAppCenterEnabled()
  }
  
  @IBAction func pushSwitchStateUpdated(_ sender: UISwitch) {
    appCenter.setPushEnabled(sender.isOn)
    sender.isOn = appCenter.isPushEnabled()
  }

  @IBAction func enableOneCollectorSwitchUpdated(_ sender: UISwitch) {
    UserDefaults.standard.set(sender.isOn, forKey: kMSOneCollectorEnabledKey)
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    if (indexPath != informationCellIndexPath &&
      indexPath.section == MSMainViewController.kStartupTypeSectionIndex) {
      didSelectStartupTypeCellAtIndexPath(indexPath)
    }
    return
  }

  func didSelectStartupTypeCellAtIndexPath(_ indexPath: IndexPath) {
    let currentSelectionIndexPath = MSMainViewController.getIndexPathForSelectedStartupTypeCell()
    toggleSelectionForCellAtIndexPath(currentSelectionIndexPath)
    toggleSelectionForCellAtIndexPath(indexPath)
  }

  static func getIndexPathForSelectedStartupTypeCell() -> IndexPath {
    let row = UserDefaults.standard.integer(forKey: kMSStartTargetKey)
    return IndexPath(row: row, section: kStartupTypeSectionIndex)
  }

  func toggleSelectionForCellAtIndexPath(_ indexPath: IndexPath) {
    let cell = self.tableView(tableView, cellForRowAt: indexPath)
    if (cell.accessoryType == .checkmark) {
      cell.accessoryType = .none
      cell.selectionStyle = .blue
    } else if (cell.accessoryType == .none) {
      cell.accessoryType = .checkmark
      cell.selectionStyle = .none
      UserDefaults.standard.set(indexPath.row, forKey: kMSStartTargetKey)
    }
  }
}
