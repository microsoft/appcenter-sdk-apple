import Cocoa

class MobileCenterViewController : NSViewController {

  var mobileCenter: MobileCenterDelegate = MobileCenterProvider.shared().mobileCenter!

  @IBOutlet var installIdLabel : NSTextField?
  @IBOutlet var appSecretLabel : NSTextField?
  @IBOutlet var logURLLabel : NSTextField?
  @IBOutlet var setEnabledButton : NSButton?

  override func viewDidLoad() {
    super.viewDidLoad()
    installIdLabel?.stringValue = mobileCenter.installId()
    appSecretLabel?.stringValue = mobileCenter.appSecret()
    logURLLabel?.stringValue = mobileCenter.logUrl()
    setEnabledButton?.state = mobileCenter.isMobileCenterEnabled() ? 1 : 0
  }

  @IBAction func setEnabled(sender : NSButton) {
    mobileCenter.setMobileCenterEnabled(sender.state == 1)
    sender.state = mobileCenter.isMobileCenterEnabled() ? 1 : 0
  }
}
