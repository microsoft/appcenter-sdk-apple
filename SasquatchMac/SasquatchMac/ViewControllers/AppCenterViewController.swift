import Cocoa

class AppCenterViewController : NSViewController {

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!

  @IBOutlet var installIdLabel : NSTextField?
  @IBOutlet var appSecretLabel : NSTextField?
  @IBOutlet var logURLLabel : NSTextField?
  @IBOutlet var userIdLabel : NSTextField?
  @IBOutlet var setEnabledButton : NSButton?

  @IBOutlet weak var deviceIdField: NSTextField!
  @IBOutlet weak var startupModeField: NSComboBox!

  override func viewDidLoad() {
    super.viewDidLoad()
    installIdLabel?.stringValue = appCenter.installId()
    appSecretLabel?.stringValue = appCenter.appSecret()
    logURLLabel?.stringValue = appCenter.logUrl()
    userIdLabel?.stringValue = UserDefaults.standard.string(forKey: "userId") ?? ""
    setEnabledButton?.state = appCenter.isAppCenterEnabled() ? 1 : 0

    deviceIdField?.stringValue = AppCenterViewController.getDeviceIdentifier()!
    let indexNumber = UserDefaults.standard.integer(forKey: kMSStartTargetKey)
    startupModeField.selectItem(at: indexNumber)
  }

  @IBAction func setEnabled(sender : NSButton) {
    appCenter.setAppCenterEnabled(sender.state == 1)
    sender.state = appCenter.isAppCenterEnabled() ? 1 : 0
  }

  @IBAction func userIdChanged(sender: NSTextField) {
    let text = sender.stringValue
    let userId = !text.isEmpty ? text : nil
    UserDefaults.standard.set(userId, forKey: "userId")
    appCenter.setUserId(userId)
  }
  // DeviceID
  class func getDeviceIdentifier() -> String? {
    let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
    let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0)
    let baseIdentifier = serialNumberAsCFString?.takeRetainedValue() as! String
        IOObjectRelease(platformExpert)
    return baseIdentifier
  }
  // Startup Mode
  @IBAction func startupModeChanged(_ sender: NSComboBox) {
    let indexNumber = startupModeField.indexOfItem(withObjectValue: startupModeField.stringValue)
    UserDefaults.standard.set(indexNumber, forKey: kMSStartTargetKey)
  }

}
