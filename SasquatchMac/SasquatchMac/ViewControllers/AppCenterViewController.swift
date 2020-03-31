// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Cocoa

// 10 MiB.
let kMSDefaultDatabaseSize = 10 * 1024 * 1024
class AppCenterViewController : NSViewController, NSTextFieldDelegate, NSTextViewDelegate {
    
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
    
  @IBOutlet weak var deviceIdField: NSTextField!
  @IBOutlet weak var startupModeField: NSComboBox!
  @IBOutlet weak var storageMaxSizeField: NSTextField!
  @IBOutlet weak var storageFileSizeField: NSTextField!
  @IBOutlet weak var signInButton: NSButton!
  @IBOutlet weak var signOutButton: NSButton!
  @IBOutlet weak var overrideCountryCodeButton: NSButton!

  @IBOutlet weak var setLogURLButton: NSButton!
  @IBOutlet weak var setAppSecretButton: NSButton!
  @IBOutlet weak var setUserIDButton: NSButton!
  
  private var dbFileDescriptor: CInt = 0
  private var dbFileSource: DispatchSourceProtocol?

  deinit {
    self.dbFileSource?.cancel()
    close(self.dbFileDescriptor)
    UserDefaults.standard.removeObserver(self, forKeyPath: kMSStorageMaxSizeKey)
  }

  override func viewWillAppear() {
    setEnabledButton?.state = appCenter.isAppCenterEnabled() ? .on : .off
    setAppSecretButton?.isEnabled = startUpModeForCurrentSession == StartupMode.AppCenter.rawValue || startUpModeForCurrentSession == StartupMode.Both.rawValue
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    installIdLabel?.stringValue = appCenter.installId()
    appSecretLabel?.stringValue = UserDefaults.standard.string(forKey: kMSAppSecret) ?? appCenter.appSecret()
    logURLLabel?.stringValue = (UserDefaults.standard.object(forKey: kMSLogUrl) ?? prodLogUrl()) as! String
    userIdLabel?.stringValue = showUserId()
    setEnabledButton?.state = appCenter.isAppCenterEnabled() ? .on : .off
  
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
    appCenter.setAppCenterEnabled(sender.state == .on)
    sender.state = appCenter.isAppCenterEnabled() ? .on : .off
  }

  @IBAction func overrideCountryCode(_ sender: NSButton) {
    let appDelegate: AppDelegate? =  NSApplication.shared.delegate as? AppDelegate
    appDelegate?.overrideCountryCode()
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

  func controlTextDidChange(_ obj: Notification) {
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
    alert.alertStyle = .warning
    switch(alert.runModal()) {
    case .alertFirstButtonReturn:
      UserDefaults.standard.removeObject(forKey: kMSLogUrl)
      appCenter.setLogUrl(prodLogUrl())
      break
    case .alertSecondButtonReturn:
      let text = textView.string ?? ""
      let logUrl = !text.isEmpty ? text : nil
      UserDefaults.standard.set(logUrl, forKey: kMSLogUrl)
      appCenter.setLogUrl(logUrl)
      break
    case .alertThirdButtonReturn:
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
    alert.alertStyle = .warning
    switch(alert.runModal()) {
    case .alertFirstButtonReturn:
      UserDefaults.standard.removeObject(forKey: kMSAppSecret)
      break
    case .alertSecondButtonReturn:
      let text = textView.string ?? ""
      let appSecret = !text.isEmpty ? text : nil
      if (appSecret != nil) {
        UserDefaults.standard.set(appSecret, forKey: kMSAppSecret)
      }
      break
    case .alertThirdButtonReturn:
      break
    default:
      break
    }
    appSecretLabel?.stringValue = (UserDefaults.standard.object(forKey: kMSAppSecret) ?? appCenter.appSecret()) as! String
  }

  @IBAction func setUserID(_ sender: NSButton) {
    let alert: NSAlert = NSAlert()
    alert.messageText = "User ID"
    alert.addButton(withTitle: "Reset")
    alert.addButton(withTitle: "Save")
    alert.addButton(withTitle: "Cancel")
    let scrollView: NSScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 40))
    let textView: NSTextView = NSTextView(frame: NSRect(x: 0, y: 0, width: 290, height: 40))
    textView.string = UserDefaults.standard.string(forKey: kMSUserIdKey) ?? ""
    scrollView.documentView = textView
    scrollView.hasVerticalScroller = true
    scrollView.contentView.scroll(NSPoint(x: 0, y: textView.frame.size.height))
    alert.accessoryView = scrollView
    alert.alertStyle = .warning
    switch(alert.runModal()) {
    case .alertFirstButtonReturn:
      UserDefaults.standard.removeObject(forKey: kMSUserIdKey)
      appCenter.setUserId(nil)
      break
    case .alertSecondButtonReturn:
      let text = textView.string
      UserDefaults.standard.set(text, forKey: kMSUserIdKey)
      appCenter.setUserId(text)
      break
    default:
      break
    }
    userIdLabel?.stringValue = showUserId()
  }

  private func prodLogUrl() -> String {
    switch startUpModeForCurrentSession {
    case StartupMode.OneCollector.rawValue, StartupMode.None.rawValue, StartupMode.Skip.rawValue: return ocProdLogUrl
    default: return acProdLogUrl
    }
  }
  
  private func prodAppSecret() -> String {
    return startUpModeForCurrentSession == StartupMode.OneCollector.rawValue ? "" : (UserDefaults.standard.object(forKey: kMSAppSecret) ?? appCenter.appSecret()) as! String
  }

  func showUserId() -> String {
    let userId = UserDefaults.standard.string(forKey: kMSUserIdKey) ?? "Unset"
    if (userId.isEmpty) {
      return "Empty string"
    }
    return userId
  }
}
