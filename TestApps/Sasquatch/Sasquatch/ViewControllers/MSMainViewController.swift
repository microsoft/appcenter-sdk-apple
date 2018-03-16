import UIKit

class MSMainViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, AppCenterProtocol {

  @IBOutlet weak var startTypeValue: UITextField!
  @IBOutlet weak var enabled: UISwitch!
  @IBOutlet weak var installId: UILabel!
  @IBOutlet weak var appSecret: UILabel!
  @IBOutlet weak var logUrl: UILabel!
  @IBOutlet weak var sdkVersion: UILabel!

  var startTypePicker = UIPickerView()
  var appCenter: AppCenterDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.enabled.isOn = appCenter.isAppCenterEnabled()
    self.installId.text = appCenter.installId()
    self.appSecret.text = appCenter.appSecret()
    self.logUrl.text = appCenter.logUrl()
    self.sdkVersion.text = appCenter.sdkVersion()
    self.setupStartType()
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setAppCenterEnabled(sender.isOn)
    sender.isOn = appCenter.isAppCenterEnabled()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? AppCenterProtocol {
      destination.appCenter = appCenter
    }
  }

  func setupStartType() {
    if UserDefaults.standard.integer(forKey: kSASAppCenterStartTypeKey) == 0 {
      UserDefaults.standard.set(MSAppCenterStartType.AppSecret.rawValue, forKey: kSASAppCenterStartTypeKey)
    }
    
    let toolbar = UIToolbar()
    toolbar.barStyle = UIBarStyle.default
    toolbar.isTranslucent = true
    toolbar.sizeToFit()
    let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MSMainViewController.startTypeChanged))
    let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: startTypeValue, action: #selector(UITextField.resignFirstResponder))
    let flexibleSpace = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
    toolbar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)
    toolbar.isUserInteractionEnabled = true

    self.startTypeValue.text = MSAppCenterStartType(rawValue: UserDefaults.standard.integer(forKey: kSASAppCenterStartTypeKey))?.name()
    self.startTypeValue.inputAccessoryView = toolbar
    self.startTypeValue.inputView = self.startTypePicker
    self.startTypePicker.delegate = self
    self.startTypePicker.dataSource = self
  }

  func startTypeChanged() {
    let startType = MSAppCenterStartType.allValues[startTypePicker.selectedRow(inComponent: 0)]
    startTypeValue.text = startType.name()
    UserDefaults.standard.set(startType.rawValue, forKey: kSASAppCenterStartTypeKey)
    startTypeValue.resignFirstResponder()
  }

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return MSAppCenterStartType.allValues.count
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return MSAppCenterStartType.allValues[row].name()
  }
}
