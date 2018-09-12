import UIKit

class MSMainViewController: UITableViewController, AppCenterProtocol {
  
  enum StartupMode: String {
    case AppCenter = "AppCenter"
    case OneCollector = "OneCollector"
    case Both = "Both"
    case None = "None"
    case Skip = "Skip"
    
    static let allValues = [AppCenter, OneCollector, Both, None, Skip]
  }

  @IBOutlet weak var appCenterEnabledSwitch: UISwitch!
  @IBOutlet weak var startupModeField: UITextField!
  @IBOutlet weak var installId: UILabel!
  @IBOutlet weak var appSecret: UILabel!
  @IBOutlet weak var logUrl: UILabel!
  @IBOutlet weak var sdkVersion: UILabel!
  @IBOutlet weak var pushEnabledSwitch: UISwitch!
  @IBOutlet weak var logFilterSwitch: UISwitch!
  @IBOutlet weak var deviceIdLabel: UILabel!

  var startupModePicker: MSEnumPicker<StartupMode>?
  var appCenter: AppCenterDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Startup mode.
    let startupMode = UserDefaults.standard.integer(forKey: kMSStartTargetKey)
    self.startupModePicker = MSEnumPicker<StartupMode>(
      textField: self.startupModeField,
      initialValue: StartupMode.allValues[startupMode],
      allValues: StartupMode.allValues,
      onChange: {(index) in UserDefaults.standard.set(index, forKey: kMSStartTargetKey)})
    
    // Make sure it is initialized before changing the startup mode.
    _ = MSTransmissionTargets.shared

    // Miscellaneous section.
    appCenter.startEventFilterService()
    self.installId.text = appCenter.installId()
    self.appSecret.text = appCenter.appSecret()
    self.logUrl.text = appCenter.logUrl()
    self.sdkVersion.text = appCenter.sdkVersion()
    self.deviceIdLabel.text = UIDevice.current.identifierForVendor?.uuidString
    
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

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? AppCenterProtocol {
      destination.appCenter = appCenter
    }
  }
}
