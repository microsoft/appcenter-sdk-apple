// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

// 10 MiB.
let kMSDefaultDatabaseSize = 10 * 1024 * 1024
let acProdLogUrl = "https://in.appcenter.ms"
let ocProdLogUrl = "https://mobile.events.data.microsoft.com"
let kMSARefreshTokenKey = "MSARefreshToken"
let kMSAppCenterBundleIdentifier = "com.microsoft.appcenter"
let kMSATokenKey = "MSAToken"

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
  @IBOutlet weak var setLogUrlButton: UIButton!
  @IBOutlet weak var setAppSecretButton: UIButton!
  @IBOutlet weak var overrideCountryCodeButton: UIButton!
  @IBOutlet weak var userId: UILabel!
  @IBOutlet weak var setUserIdButton: UIButton!
  
  var appCenter: AppCenterDelegate!
  private var startupModePicker: MSEnumPicker<StartupMode>?
  private var eventFilterStarted = false
  private var dbFileDescriptor: CInt = 0
  private var dbFileSource: DispatchSourceProtocol?

  let startUpModeForCurrentSession: NSInteger = (UserDefaults.standard.object(forKey: kMSStartTargetKey) ?? 0) as! NSInteger
  
  deinit {
    self.dbFileSource?.cancel()
    close(self.dbFileDescriptor)
    UserDefaults.standard.removeObserver(self, forKeyPath: kMSStorageMaxSizeKey)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Startup mode.
    let startupMode = UserDefaults.standard.integer(forKey: kMSStartTargetKey)
    self.startupModePicker = MSEnumPicker<StartupMode> (
      textField: self.startupModeField,
      allValues: StartupMode.allValues,
      onChange: { index in
        UserDefaults.standard.set(index, forKey: kMSStartTargetKey)
        UserDefaults.standard.removeObject(forKey: kMSLogUrl)
      }
    )
    self.startupModeField.delegate = self.startupModePicker
    self.startupModeField.text = StartupMode.allValues[startupMode].rawValue
    self.startupModeField.tintColor = UIColor.clear
    
    // Make sure it is initialized before changing the startup mode.
    // Do not initialize too early if we start from library later.
    // Otherwise channelGroup would be nil.
    if (StartupMode.allValues[startupMode] != .Skip && StartupMode.allValues[startupMode] != .None) {
        _ = MSTransmissionTargets.shared
    }
    
    if let msaUserId = UserDefaults.standard.string(forKey: kMSATokenKey),
        let refreshToken = UserDefaults.standard.string(forKey: kMSARefreshTokenKey) {
        let provider = MSAnalyticsAuthenticationProvider(authenticationType: .msaCompact, ticketKey: msaUserId, delegate: MSAAnalyticsAuthenticationProvider.getInstance(refreshToken, self))
        MSAnalyticsTransmissionTarget.addAuthenticationProvider(authenticationProvider:provider)
    }

    // Storage size section.
    let storageMaxSize = UserDefaults.standard.object(forKey: kMSStorageMaxSizeKey) as? Int ?? kMSDefaultDatabaseSize
    UserDefaults.standard.addObserver(self, forKeyPath: kMSStorageMaxSizeKey, options: .new, context: nil)
    self.storageMaxSizeField.text = "\(storageMaxSize / 1024)"
    self.storageMaxSizeField.addTarget(self, action: #selector(storageMaxSizeUpdated(_:)), for: .editingChanged)
    self.storageMaxSizeField.inputAccessoryView = self.toolBarForKeyboard()
    
    if let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
#if !targetEnvironment(macCatalyst)
      let dbFile = supportDirectory.appendingPathComponent(kMSAppCenterBundleIdentifier).appendingPathComponent("Logs.sqlite")
#else
      let dbFile = supportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier!).appendingPathComponent(kMSAppCenterBundleIdentifier).appendingPathComponent("Logs.sqlite")
#endif
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
    self.appSecret.text = UserDefaults.standard.string(forKey: kMSAppSecret) ?? appCenter.appSecret()
    self.logUrl.text = UserDefaults.standard.string(forKey: kMSLogUrl) ?? defaultLogUrl()
    self.sdkVersion.text = appCenter.sdkVersion()
    self.deviceIdLabel.text = UIDevice.current.identifierForVendor?.uuidString
    self.userId.text = self.showUserId()
    self.setAppSecretButton.isEnabled = StartupMode.allValues[startUpModeForCurrentSession] == StartupMode.AppCenter || StartupMode.allValues[startUpModeForCurrentSession] == StartupMode.Both

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
#if !targetEnvironment(macCatalyst)
    appCenter.setPushEnabled(sender.isOn)
#else
    showAlert(message: "AppCenter Push is not supported by Mac Catalyst")
#endif
    updateViewState()
  }
    
  @IBAction func overrideCountryCode(_ sender: UIButton) {
    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
    appDelegate?.requestLocation()
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
  
  @IBAction func userIdSetting(_ sender: UIButton) {
    let alertController = UIAlertController(title: "User Id",
                                            message: nil,
                                            preferredStyle:.alert)
    alertController.addTextField { (userIdTextField) in
        userIdTextField.text = UserDefaults.standard.string(forKey: kMSUserIdKey)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    let saveAction = UIAlertAction(title: "Save", style: .default, handler: {
        (_ action : UIAlertAction) -> Void in
        let text = alertController.textFields?[0].text ?? ""
        UserDefaults.standard.set(text, forKey: kMSUserIdKey)
        self.appCenter.setUserId(text)
        self.userId.text = self.showUserId()
    })
    let resetAction = UIAlertAction(title: "Reset", style: .destructive, handler: {
        (_ action : UIAlertAction) -> Void in
        UserDefaults.standard.removeObject(forKey: kMSUserIdKey)
        self.appCenter.setUserId(nil)
        self.userId.text = self.showUserId()
    })
    alertController.addAction(cancelAction)
    alertController.addAction(saveAction)
    alertController.addAction(resetAction)
    self.present(alertController, animated: true, completion: nil)
  }
  
  @IBAction func logUrlSetting(_ sender: UIButton) {
    let alertController = UIAlertController(title: "Log Url",
                                            message: nil,
                                            preferredStyle:.alert)
    alertController.addTextField { (logUrlTextField) in
      logUrlTextField.text = UserDefaults.standard.string(forKey: kMSLogUrl) ?? self.defaultLogUrl()
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    let saveAction = UIAlertAction(title: "Save", style: .default, handler: {
      (_ action : UIAlertAction) -> Void in
      let text = alertController.textFields?[0].text ?? ""
      UserDefaults.standard.set(text, forKey: kMSLogUrl)
      self.appCenter.setLogUrl(text)
      self.logUrl.text = text
    })
    let resetAction = UIAlertAction(title: "Reset", style: .destructive, handler: {
      (_ action : UIAlertAction) -> Void in
      UserDefaults.standard.removeObject(forKey: kMSLogUrl)
      self.appCenter.setLogUrl(self.defaultLogUrl())
      self.logUrl.text = self.defaultLogUrl()
    })
    alertController.addAction(cancelAction)
    alertController.addAction(saveAction)
    alertController.addAction(resetAction)
    self.present(alertController, animated: true, completion: nil)
  }
  
  @IBAction func appSecretSetting(_ sender: UIButton) {
    let alertController = UIAlertController(title: "App Secret",
                                            message: "Please restart app after updating the appsecret",
                                            preferredStyle:.alert)
    alertController.addTextField { (appSecretTextField) in
      appSecretTextField.text = UserDefaults.standard.string(forKey: kMSAppSecret) ?? self.appCenter.appSecret()
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    let saveAction = UIAlertAction(title: "Save", style: .default, handler: {
      (_ action : UIAlertAction) -> Void in
      let text = alertController.textFields?[0].text ?? ""
      UserDefaults.standard.set(text, forKey: kMSAppSecret)
      self.appSecret.text = text
    })
    let resetAction = UIAlertAction(title: "Reset", style: .destructive, handler: {
      (_ action : UIAlertAction) -> Void in
      UserDefaults.standard.removeObject(forKey: kMSAppSecret)
      self.appSecret.text = self.appCenter.appSecret()
    })
    alertController.addAction(cancelAction)
    alertController.addAction(saveAction)
    alertController.addAction(resetAction)
    self.present(alertController, animated: true, completion: nil)
  }

  @IBAction func dismissKeyboard(_ sender: UITextField!) {
    sender.resignFirstResponder()
  }

  @objc func storageMaxSizeUpdated(_ sender: UITextField) {
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

  @objc func doneClicked() {
    dismissKeyboard(self.storageMaxSizeField)
  }
  
  func defaultLogUrl() -> String {
    switch StartupMode.allValues[startUpModeForCurrentSession] {
    case .OneCollector, .None, .Skip:
      return ocProdLogUrl
    default:
      #if ACTIVE_COMPILATION_CONDITION_PUPPET
      return kMSIntLogUrl
      #else
      return acProdLogUrl
      #endif
    }
  }
    
  func showUserId () -> String {
    let userId = UserDefaults.standard.string(forKey: kMSUserIdKey) ?? "Unset";
    if (userId.isEmpty) {
        return "Empty string";
    }
    return userId;
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? AppCenterProtocol {
      destination.appCenter = appCenter
    }
  }
  
  func showAlert(message : String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    self.present(alert, animated: true)
    let duration: Double = 2
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
        alert.dismiss(animated: true)
    }
  }
}
