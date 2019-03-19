import Cocoa
import CoreLocation

// 10 MiB.
let kMSDefaultDatabaseSize = 10 * 1024 * 1024
class AppCenterViewController : NSViewController, NSTextFieldDelegate, NSTextViewDelegate, CLLocationManagerDelegate {
    
  enum StartupMode: NSInteger {
    case AppCenter
    case OneCollector
    case Both
    case None
    case Skip
  }

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!
  var currentAction = AuthenticationViewController.AuthAction.signin

  let kMSAppCenterBundleIdentifier = "com.microsoft.appcenter"
  let acProdLogUrl = "https://in.appcenter.ms"
  let ocProdLogUrl = "https://mobile.events.data.microsoft.com"
  let startUpModeForCurrentSession: NSInteger = (UserDefaults.standard.object(forKey: kMSStartTargetKey) ?? 0) as! NSInteger

  @IBOutlet var installIdLabel : NSTextField?
  @IBOutlet var appSecretLabel : NSTextField?
  @IBOutlet var logURLLabel : NSTextField?
  @IBOutlet var userIdLabel : NSTextField?
  @IBOutlet var setEnabledButton : NSButton?
  @IBOutlet var overrideCountryCodeButton: NSButton!

  private var locationManager: CLLocationManager = CLLocationManager()
    
  @IBOutlet weak var deviceIdField: NSTextField!
  @IBOutlet weak var startupModeField: NSComboBox!
  @IBOutlet weak var storageMaxSizeField: NSTextField!
  @IBOutlet weak var storageFileSizeField: NSTextField!
  @IBOutlet weak var signInButton: NSButton!
  @IBOutlet weak var signOutButton: NSButton!
  @IBOutlet weak var setLogURLButton: NSButton!
  @IBOutlet weak var setAppSecretButton: NSButton!
  
  private var dbFileDescriptor: CInt = 0
  private var dbFileSource: DispatchSourceProtocol?

  deinit {
    self.dbFileSource?.cancel()
    close(self.dbFileDescriptor)
    UserDefaults.standard.removeObserver(self, forKeyPath: kMSStorageMaxSizeKey)
  }

  override func viewWillAppear() {
    setEnabledButton?.state = appCenter.isAppCenterEnabled() ? 1 : 0
    setAppSecretButton?.isEnabled = startUpModeForCurrentSession == StartupMode.OneCollector.rawValue ? false : true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    installIdLabel?.stringValue = appCenter.installId()
    appSecretLabel?.stringValue = appCenter.appSecret()
    logURLLabel?.stringValue = (UserDefaults.standard.object(forKey: kMSLogUrl) ?? prodLogUrl()) as! String
    userIdLabel?.stringValue = UserDefaults.standard.string(forKey: kMSUserIdKey) ?? ""
    setEnabledButton?.state = appCenter.isAppCenterEnabled() ? 1 : 0
    
    self.locationManager.delegate = self
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
  
    deviceIdField?.stringValue = AppCenterViewController.getDeviceIdentifier()!
    let indexNumber = UserDefaults.standard.integer(forKey: kMSStartTargetKey)
    startupModeField.selectItem(at: indexNumber)

    // Storage size section.
    storageMaxSizeField.delegate = self
    let storageMaxSize = UserDefaults.standard.object(forKey: kMSStorageMaxSizeKey) as? Int ?? kMSDefaultDatabaseSize
    UserDefaults.standard.addObserver(self, forKeyPath: kMSStorageMaxSizeKey, options: .new, context: nil)
    self.storageMaxSizeField?.stringValue = "\(storageMaxSize / 1024)"

    if let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      let dbFile = supportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier!).appendingPathComponent(kMSAppCenterBundleIdentifier).appendingPathComponent("Logs.sqlite")
      func getFileSize(_ file: URL) -> Int {
        return (try? file.resourceValues(forKeys:[.fileSizeKey]))?.fileSize ?? 0
      }
      self.dbFileDescriptor = dbFile.withUnsafeFileSystemRepresentation { fileSystemPath -> CInt in
        return open(fileSystemPath!, O_EVTONLY)
      }
      self.dbFileSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: self.dbFileDescriptor, eventMask: [.write], queue: DispatchQueue.main)
      self.dbFileSource!.setEventHandler {
        self.storageFileSizeField.stringValue = "\(getFileSize(dbFile) / 1024)"
      }
      self.dbFileSource!.resume()
      self.storageFileSizeField.stringValue = "\(getFileSize(dbFile) / 1024)"
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    self.locationManager.stopUpdatingLocation()
    let userLocation:CLLocation = locations[0] as CLLocation
    CLGeocoder().reverseGeocodeLocation(userLocation) { (placemarks, error) in
      if error == nil {
        self.appCenter.setCountryCode(placemarks?.first?.isoCountryCode)
      }
    }
  }
  
  func locationManager(_ Manager: CLLocationManager, didFailWithError error: Error) {
    print("Failed to find user's location: \(error.localizedDescription)")
  }

  @IBAction func setEnabled(sender : NSButton) {
    appCenter.setAppCenterEnabled(sender.state == 1)
    sender.state = appCenter.isAppCenterEnabled() ? 1 : 0
  }

  @IBAction func userIdChanged(sender: NSTextField) {
    let text = sender.stringValue
    let userId = !text.isEmpty ? text : nil
    UserDefaults.standard.set(userId, forKey: kMSUserIdKey)
    appCenter.setUserId(userId)
  }
  
  @IBAction func overrideCountryCode(_ sender: NSButton) {
    if CLLocationManager.locationServicesEnabled() {
      self.locationManager.startUpdatingLocation()
    }
    else {
      let alert : NSAlert = NSAlert()
      alert.messageText = "Location service is disabled"
      alert.informativeText = "Please enable location service on your Mac."
      alert.addButton(withTitle: "OK")
      alert.runModal()
    }
  }

  // Get device identifier.
  class func getDeviceIdentifier() -> String? {
    let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
    let platformUUIDAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
    let baseIdentifier = platformUUIDAsCFString?.takeRetainedValue() as! String
        IOObjectRelease(platformExpert)
    return baseIdentifier
  }

  // Startup Mode.
  @IBAction func startupModeChanged(_ sender: NSComboBox) {
    let indexNumber = startupModeField.indexOfItem(withObjectValue: startupModeField.stringValue)
    UserDefaults.standard.set(indexNumber, forKey: kMSStartTargetKey)
    UserDefaults.standard.removeObject(forKey: kMSLogUrl)
  }

  // Storage Max Size
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    let storageMaxSize = UserDefaults.standard.object(forKey: kMSStorageMaxSizeKey) as? Int ?? kMSDefaultDatabaseSize
    self.storageMaxSizeField?.stringValue = "\(storageMaxSize / 1024)"
  }

  override func controlTextDidChange(_ obj: Notification) {
    let text = obj.object as? NSTextField
    if text == self.storageMaxSizeField {
      let maxSize = Int(self.storageMaxSizeField.stringValue) ?? 0
      UserDefaults.standard.set(maxSize * 1024, forKey: kMSStorageMaxSizeKey)
    }
  }

  // Authentication
  func showSignInController(action: AuthenticationViewController.AuthAction) {
    currentAction = action
    self.performSegue(withIdentifier: "ShowSignIn", sender: self)
  }

  @IBAction func signInClicked(_ sender: NSButton) {
    showSignInController(action: AuthenticationViewController.AuthAction.signin)
  }

  @IBAction func singOutClicked(_ sender: NSButton) {
    showSignInController(action: AuthenticationViewController.AuthAction.signout)
  }

  override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
    if let signInController = segue.destinationController as? AuthenticationViewController {
      signInController.action = currentAction
    }
  }
  
  @IBAction func setLogURL(_ sender: NSButton) {
    let alert: NSAlert = NSAlert()
    alert.messageText = "Log URL"
    alert.addButton(withTitle: "Reset")
    alert.addButton(withTitle: "Save")
    alert.addButton(withTitle: "Cancel")
    let scrollView: NSScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 40))
    let textView: NSTextView = NSTextView(frame: NSRect(x: 0, y: 0, width: 290, height: 40))
    textView.string = UserDefaults.standard.string(forKey: kMSLogUrl) ?? prodLogUrl()
    scrollView.documentView = textView
    scrollView.hasVerticalScroller = true
    scrollView.contentView.scroll(NSPoint(x: 0, y: textView.frame.size.height))
    alert.accessoryView = scrollView
    alert.alertStyle = NSWarningAlertStyle
    switch(alert.runModal()) {
    case NSAlertFirstButtonReturn:
      UserDefaults.standard.removeObject(forKey: kMSLogUrl)
      appCenter.setLogUrl(prodLogUrl())
      break
    case NSAlertSecondButtonReturn:
      let text = textView.string ?? ""
      let logUrl = !text.isEmpty ? text : nil
      UserDefaults.standard.set(logUrl, forKey: kMSLogUrl)
      appCenter.setLogUrl(logUrl)
      break
    case NSAlertThirdButtonReturn:
      break
    default:
      break
    }
    logURLLabel?.stringValue = (UserDefaults.standard.object(forKey: kMSLogUrl) ?? prodLogUrl()) as! String
  }
  
  @IBAction func setAppSecret(_ sender: NSButton) {
    let alert: NSAlert = NSAlert()
    alert.messageText = "AppSecret"
    alert.informativeText = "Please restart app after updating the appsecret"
    alert.addButton(withTitle: "Reset")
    alert.addButton(withTitle: "Save")
    alert.addButton(withTitle: "Cancel")
    let scrollView: NSScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 40))
    let textView: NSTextView = NSTextView(frame: NSRect(x: 0, y: 0, width: 290, height: 40))
    textView.string = UserDefaults.standard.string(forKey: kMSAppSecret) ?? appCenter.appSecret()
    scrollView.documentView = textView
    scrollView.hasVerticalScroller = true
    scrollView.contentView.scroll(NSPoint(x: 0, y: textView.frame.size.height))
    alert.accessoryView = scrollView
    alert.alertStyle = NSWarningAlertStyle
    switch(alert.runModal()) {
    case NSAlertFirstButtonReturn:
      UserDefaults.standard.removeObject(forKey: kMSAppSecret)
      break
    case NSAlertSecondButtonReturn:
      let text = textView.string ?? ""
      let appSecret = !text.isEmpty ? text : nil
      if (appSecret != nil) {
        UserDefaults.standard.set(appSecret, forKey: kMSAppSecret)
      }
      break
    case NSAlertThirdButtonReturn:
      break
    default:
      break
    }
    appSecretLabel?.stringValue = (UserDefaults.standard.object(forKey: kMSAppSecret) ?? appCenter.appSecret()) as! String
  }

  private func prodLogUrl() -> String {
    return startUpModeForCurrentSession == StartupMode.OneCollector.rawValue ? ocProdLogUrl : acProdLogUrl
  }
  
  private func prodAppSecret() -> String {
    return startUpModeForCurrentSession == StartupMode.OneCollector.rawValue ? "" : (UserDefaults.standard.object(forKey: kMSAppSecret) ?? appCenter.appSecret()) as! String
  }
}
