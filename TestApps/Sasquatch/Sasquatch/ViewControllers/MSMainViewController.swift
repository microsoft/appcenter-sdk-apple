import UIKit

class MSMainViewController: UITableViewController, AppCenterProtocol {
  
  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var oneCollectorEnabled: UISwitch!
  @IBOutlet weak var installId: UILabel!
  @IBOutlet weak var appSecret: UILabel!
  @IBOutlet weak var logUrl: UILabel!
  @IBOutlet weak var sdkVersion: UILabel!
  @IBOutlet weak var startTarget: UISegmentedControl!
  @IBOutlet weak var pushEnabledSwitch: UISwitch!

  var appCenter: AppCenterDelegate!

  static let kStartupTypeSectionIndex = 1
  var appTargetCellIndexPath = IndexPath(row:0, section:kStartupTypeSectionIndex)
  var libraryTargetCellIndexPath = IndexPath(row:1, section:kStartupTypeSectionIndex)
  var bothTargetsCellIndexPath = IndexPath(row: 2, section: kStartupTypeSectionIndex)

  override func viewDidLoad() {
    super.viewDidLoad()
    self.enabled.isOn = appCenter.isAppCenterEnabled()
    //self.oneCollectorEnabled.isOn = UserDefaults.standard.bool(forKey: "isOneCollectorEnabled")
    self.installId.text = appCenter.installId()
    self.appSecret.text = appCenter.appSecret()
    self.logUrl.text = appCenter.logUrl()
    self.sdkVersion.text = appCenter.sdkVersion()
    let startupTypeCellIndexPath = MSMainViewController.getIndexPathForSelectedStartupTypeCell()
    toggleSelectionForCellAtIndexPath(startupTypeCellIndexPath)
    pushEnabledSwitch.isOn = appCenter.isPushEnabled()
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
    let alert = UIAlertController(title: "Restart", message: "Please restart the app for the change to take effect.",
                                  preferredStyle: .actionSheet)
    let exitAction = UIAlertAction(title: "Exit", style: .destructive) {_ in
      UserDefaults.standard.set(sender.isOn, forKey: "isOneCollectorEnabled")
      exit(0)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {_ in
      sender.isOn = UserDefaults.standard.bool(forKey: "isOneCollectorEnabled")
      alert.dismiss(animated: true, completion: nil)
    }
    alert.addAction(exitAction)
    alert.addAction(cancelAction)
    
    // Support display in iPad.
    alert.popoverPresentationController?.sourceView = self.oneCollectorEnabled.superview;
    alert.popoverPresentationController?.sourceRect = self.oneCollectorEnabled.frame;
    self.present(alert, animated: true, completion: nil)
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    if (indexPath.section == MSMainViewController.kStartupTypeSectionIndex) {
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
    let row = UserDefaults.standard.integer(forKey: "startTarget")
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
      UserDefaults.standard.set(indexPath.row, forKey: "startTarget")
    }
  }
}
