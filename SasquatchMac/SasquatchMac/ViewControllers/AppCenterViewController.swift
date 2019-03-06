import Cocoa

// 10 MiB.
let kMSDefaultDatabaseSize = 10 * 1024 * 1024

class AppCenterViewController : NSViewController, NSTextFieldDelegate, NSTextViewDelegate {

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!
  var currentAction = AuthenticationViewController.AuthAction.signin

  let kMSAppCenterBundleIdentifier = "com.microsoft.appcenter";
  let prodLogUrl = "https://in.appcenter.ms"

  @IBOutlet var installIdLabel : NSTextField?
  @IBOutlet var appSecretLabel : NSTextField?
  @IBOutlet var logURLLabel : NSTextField?
  @IBOutlet var userIdLabel : NSTextField?
  @IBOutlet var setEnabledButton : NSButton?

  @IBOutlet weak var deviceIdField: NSTextField!
  @IBOutlet weak var startupModeField: NSComboBox!
  @IBOutlet weak var storageMaxSizeField: NSTextField!
  @IBOutlet weak var storageFileSizeField: NSTextField!
  @IBOutlet weak var signInButton: NSButton!
  @IBOutlet weak var signOutButton: NSButton!
  @IBOutlet weak var setLogURLButton: NSButton!

  private var dbFileDescriptor: CInt = 0
  private var dbFileSource: DispatchSourceProtocol?

  deinit {
      self.dbFileSource?.cancel()
      close(self.dbFileDescriptor)
      UserDefaults.standard.removeObserver(self, forKeyPath: kMSStorageMaxSizeKey)
  }

  override func viewWillAppear() {
    setEnabledButton?.state = appCenter.isAppCenterEnabled() ? 1 : 0
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    installIdLabel?.stringValue = appCenter.installId()
    appSecretLabel?.stringValue = appCenter.appSecret()
    logURLLabel?.stringValue = appCenter.logUrl()
    userIdLabel?.stringValue = UserDefaults.standard.string(forKey: kMSUserIdKey) ?? ""
    setEnabledButton?.state = appCenter.isAppCenterEnabled() ? 1 : 0

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
  }

  // Storage Max Size
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    let storageMaxSize = UserDefaults.standard.object(forKey: kMSStorageMaxSizeKey) as? Int ?? kMSDefaultDatabaseSize
    self.storageMaxSizeField?.stringValue = "\(storageMaxSize / 1024)"
  }

  override func controlTextDidChange(_ obj: Notification) {
    let text = obj.object as? NSTextField
    if text == self.storageMaxSizeField{
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
    textView.string = UserDefaults.standard.string(forKey: kMSLogUrl) ?? prodLogUrl
    scrollView.documentView = textView
    scrollView.hasVerticalScroller = true
    scrollView.contentView.scroll(NSPoint(x: 0, y: textView.frame.size.height))
    alert.accessoryView = scrollView
    alert.alertStyle = NSWarningAlertStyle
    switch(alert.runModal()) {
    case NSAlertFirstButtonReturn:
      UserDefaults.standard.set(prodLogUrl, forKey: kMSLogUrl)
      break
    case NSAlertSecondButtonReturn:
      let text = textView.string ?? ""
      let logUrl = !text.isEmpty ? text : nil
      UserDefaults.standard.set(logUrl, forKey: kMSLogUrl)
      break
    case NSAlertThirdButtonReturn:
      break
    default:
      break
    }
  }

}
