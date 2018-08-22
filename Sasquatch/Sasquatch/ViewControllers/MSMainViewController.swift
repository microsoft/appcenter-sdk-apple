import UIKit

class MSMainViewController: UITableViewController, AppCenterProtocol {
  
  @IBOutlet weak var appCenterEnabledSwitch: UISwitch!
  @IBOutlet weak var installId: UILabel!
  @IBOutlet weak var appSecret: UILabel!
  @IBOutlet weak var logUrl: UILabel!
  @IBOutlet weak var sdkVersion: UILabel!
  @IBOutlet weak var pushEnabledSwitch: UISwitch!
  @IBOutlet weak var logFilterSwitch: UISwitch!
  
  var appCenter: AppCenterDelegate!

  static let kStartupTypeSectionIndex = 1
  var appTargetCellIndexPath = IndexPath(row:0, section:kStartupTypeSectionIndex)
  var libraryTargetCellIndexPath = IndexPath(row:1, section:kStartupTypeSectionIndex)
  var bothTargetsCellIndexPath = IndexPath(row: 2, section: kStartupTypeSectionIndex)
  var informationCellIndexPath = IndexPath(row: 3, section: kStartupTypeSectionIndex)

  override func viewDidLoad() {
    super.viewDidLoad()

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
    appCenter.startEventFilterService()
    self.installId.text = appCenter.installId()
    self.appSecret.text = appCenter.appSecret()
    self.logUrl.text = appCenter.logUrl()
    self.sdkVersion.text = appCenter.sdkVersion()
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateViewState()
  }
  
  func updateViewState() {
    self.appCenterEnabledSwitch.isOn = appCenter.isAppCenterEnabled()
    self.pushEnabledSwitch.isOn = appCenter.isPushEnabled()
    self.logFilterSwitch.isOn = appCenter.isEventFilterEnabled()
  }

  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setAppCenterEnabled(sender.isOn)
    updateViewState()
  }
  
  @IBAction func pushSwitchStateUpdated(_ sender: UISwitch) {
    appCenter.setPushEnabled(sender.isOn)
    updateViewState()
  }
  
  @IBAction func logFilterSwitchChanged(_ sender: UISwitch) {
    appCenter.setEventFilterEnabled(sender.isOn)
    updateViewState()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    if (indexPath != informationCellIndexPath &&
      indexPath.section == MSMainViewController.kStartupTypeSectionIndex) {
      didSelectStartupTypeCellAtIndexPath(indexPath)
    }
    return
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? AppCenterProtocol {
      destination.appCenter = appCenter
    }
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
