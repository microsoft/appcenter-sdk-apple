import UIKit

class MSMainViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, AppCenterProtocol {
  
  enum StartupMode : String {
    case AppSecret = "App Secret"
    case Target = "Target"
    case Both = "Both"
    case NoSecret = "No Secret"
    case SkipStart = "Skip Start"
    
    static let allValues = [AppSecret, Target, Both, NoSecret, SkipStart]
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

  var appCenter: AppCenterDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Startup mode.
    let startupMode = UserDefaults.standard.integer(forKey: kMSStartTargetKey)
    self.startupModeField.delegate = self
    self.startupModeField.text = StartupMode.allValues[startupMode].rawValue
    self.startupModeField.tintColor = UIColor.clear

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

  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    if textField == self.startupModeField {
      showStartupModePicker()
      return true
    }
    return false
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    return false
  }
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return StartupMode.allValues.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return StartupMode.allValues[row].rawValue
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    UserDefaults.standard.set(row, forKey: kMSStartTargetKey)
    self.startupModeField.text = StartupMode.allValues[row].rawValue
  }
  
  func showStartupModePicker() {
    let startupModePickerView = UIPickerView()
    startupModePickerView.backgroundColor = UIColor.white
    startupModePickerView.showsSelectionIndicator = true
    startupModePickerView.dataSource = self
    startupModePickerView.delegate = self
    
    // Select current type.
    let startupMode = StartupMode(rawValue: self.startupModeField.text!)!
    startupModePickerView.selectRow(StartupMode.allValues.index(of: startupMode)!, inComponent: 0, animated: false)
    
    let toolbar: UIToolbar? = toolBarForPicker()
    self.startupModeField.inputView = startupModePickerView
    self.startupModeField.inputAccessoryView = toolbar
  }
  
  func toolBarForPicker() -> UIToolbar {
    let toolbar = UIToolbar()
    toolbar.sizeToFit()
    let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneClicked))
    toolbar.items = [flexibleSpace, doneButton]
    return toolbar
  }
  
  func doneClicked() {
    self.startupModeField.resignFirstResponder()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? AppCenterProtocol {
      destination.appCenter = appCenter
    }
  }
}
