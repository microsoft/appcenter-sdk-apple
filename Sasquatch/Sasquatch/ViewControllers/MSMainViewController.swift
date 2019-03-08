import UIKit

// 10 MiB.
let kMSDefaultDatabaseSize = 10 * 1024 * 1024

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
  @IBOutlet weak var storageMaxSizeField: UITextField!
  @IBOutlet weak var storageFileSizeLabel: UILabel!
  @IBOutlet weak var userIdField: UITextField!

  var appCenter: AppCenterDelegate!
  private var startupModePicker: MSEnumPicker<StartupMode>?
  private var eventFilterStarted = false
  private var dbFileDescriptor: CInt = 0
  private var dbFileSource: DispatchSourceProtocol?

  deinit {
    self.dbFileSource?.cancel()
    close(self.dbFileDescriptor)
    UserDefaults.standard.removeObserver(self, forKeyPath: kMSStorageMaxSizeKey)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Startup mode.
    let startupMode = UserDefaults.standard.integer(forKey: kMSStartTargetKey)
    self.startupModePicker = MSEnumPicker<StartupMode>(
      textField: self.startupModeField,
      allValues: StartupMode.allValues,
      onChange: {(index) in UserDefaults.standard.set(index, forKey: kMSStartTargetKey)})
    self.startupModeField.delegate = self.startupModePicker
    self.startupModeField.text = StartupMode.allValues[startupMode].rawValue
    self.startupModeField.tintColor = UIColor.clear
    
    // Make sure it is initialized before changing the startup mode.
    _ = MSTransmissionTargets.shared

    // Storage size section.
    let storageMaxSize = UserDefaults.standard.object(forKey: kMSStorageMaxSizeKey) as? Int ?? kMSDefaultDatabaseSize
    UserDefaults.standard.addObserver(self, forKeyPath: kMSStorageMaxSizeKey, options: .new, context: nil)
    self.storageMaxSizeField.text = "\(storageMaxSize / 1024)"
    self.storageMaxSizeField.addTarget(self, action: #selector(storageMaxSizeUpdated(_:)), for: .editingChanged)
    self.storageMaxSizeField.inputAccessoryView = self.toolBarForKeyboard()
    if let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      let dbFile = supportDirectory.appendingPathComponent("com.microsoft.appcenter").appendingPathComponent("Logs.sqlite")
      func getFileSize(_ file: URL) -> Int {
        return (try? file.resourceValues(forKeys:[.fileSizeKey]))?.fileSize ?? 0
      }
      self.dbFileDescriptor = dbFile.withUnsafeFileSystemRepresentation { fileSystemPath -> CInt in
        return open(fileSystemPath!, O_EVTONLY)
      }
      self.dbFileSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: self.dbFileDescriptor, eventMask: [.write], queue: DispatchQueue.main)
      self.dbFileSource!.setEventHandler {
        self.storageFileSizeLabel.text = "\(getFileSize(dbFile) / 1024) KiB"
      }
      self.dbFileSource!.resume()
      self.storageFileSizeLabel.text = "\(getFileSize(dbFile) / 1024) KiB"
    }

    // Miscellaneous section.
    self.installId.text = appCenter.installId()
    self.appSecret.text = appCenter.appSecret()
    self.logUrl.text = appCenter.logUrl()
    self.sdkVersion.text = appCenter.sdkVersion()
    self.deviceIdLabel.text = UIDevice.current.identifierForVendor?.uuidString
    self.userIdField.text = UserDefaults.standard.string(forKey: kMSUserIdKey)

    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    let storageMaxSize = UserDefaults.standard.object(forKey: kMSStorageMaxSizeKey) as? Int ?? kMSDefaultDatabaseSize
    self.storageMaxSizeField.text = "\(storageMaxSize / 1024)"
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateViewState()
  }

  func updateViewState() {
    self.appCenterEnabledSwitch.isOn = appCenter.isAppCenterEnabled()
    self.pushEnabledSwitch.isOn = appCenter.isPushEnabled()
    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    self.logFilterSwitch.isOn = MSEventFilter.isEnabled()
    #else
    self.logFilterSwitch.isOn = false
    let cell = self.logFilterSwitch.superview!.superview as! UITableViewCell
    cell.isUserInteractionEnabled = false
    cell.contentView.alpha = 0.5
    #endif
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
    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    if !eventFilterStarted {
      MSAppCenter.startService(MSEventFilter.self)
      eventFilterStarted = true
    }
    MSEventFilter.setEnabled(sender.isOn)
    updateViewState()
    #endif
  }

  @IBAction func userIdChanged(_ sender: UITextField) {
    let text = sender.text ?? ""
    let userId = !text.isEmpty ? text : nil
    UserDefaults.standard.set(userId, forKey: kMSUserIdKey)
    appCenter.setUserId(userId)
  }

  @IBAction func dismissKeyboard(_ sender: UITextField!) {
    sender.resignFirstResponder()
  }

  func storageMaxSizeUpdated(_ sender: UITextField) {
    let maxSize = Int(sender.text ?? "0") ?? 0
    sender.text = "\(maxSize)"
    UserDefaults.standard.set(maxSize * 1024, forKey: kMSStorageMaxSizeKey)
  }

  func toolBarForKeyboard() -> UIToolbar {
    let toolbar = UIToolbar()
    toolbar.sizeToFit()
    let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneClicked))
    toolbar.items = [flexibleSpace, doneButton]
    return toolbar
  }

  func doneClicked() {
    dismissKeyboard(self.storageMaxSizeField)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? AppCenterProtocol {
      destination.appCenter = appCenter
    }
  }
}
