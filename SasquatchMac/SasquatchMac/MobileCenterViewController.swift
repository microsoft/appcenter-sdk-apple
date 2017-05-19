import Cocoa

class MobileCenterViewController : NSViewController, MobileCenterProtocol {

  var mobileCenter: MobileCenterDelegate? {
    didSet {
      self.updateUIValues()
    }
  }

  @IBOutlet var installIdLabel : NSTextField?
  @IBOutlet var appSecretLabel : NSTextField?
  @IBOutlet var logURLLabel : NSTextField?
  @IBOutlet var setEnabledButton : NSButton?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.updateUIValues()
  }

  @IBAction func setEnabled(sender : NSButton) {
    guard let `mobileCenter` = mobileCenter else {
      return
    }
    mobileCenter.setMobileCenterEnabled(sender.state == 1)
    sender.state = mobileCenter.isMobileCenterEnabled() ? 1 : 0
  }

  private func updateUIValues() {
    guard let `mobileCenter` = mobileCenter else {
      return;
    }
    installIdLabel?.stringValue = mobileCenter.installId()
    appSecretLabel?.stringValue = mobileCenter.appSecret()
    logURLLabel?.stringValue = mobileCenter.logUrl()
    setEnabledButton?.state = mobileCenter.isCrashesEnabled() ? 1 : 0
  }
}
