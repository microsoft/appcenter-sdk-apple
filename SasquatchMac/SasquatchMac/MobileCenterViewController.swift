import Cocoa

class MobileCenterViewController : NSViewController {

  var mobileCenter: MobileCenterDelegate?

  @IBOutlet var installIdLabel : NSTextField?
  @IBOutlet var appSecretLabel : NSTextField?
  @IBOutlet var logURLLabel : NSTextField?
  @IBOutlet var setEnabledButton : NSButton?

  override func viewDidLoad() {
    super.viewDidLoad()
    updateMCState()
  }

  @IBAction func setEnabled(sender : NSButton) {
    mobileCenter?.setMobileCenterEnabled(sender.state == 1)
    sender.state = mobileCenter!.isMobileCenterEnabled() ? 1 : 0
  }

  func updateMCState() {
    mobileCenter = MobileCenterProvider.shared().mobileCenter
    installIdLabel?.stringValue = mobileCenter?.installId() ?? ""
    appSecretLabel?.stringValue = mobileCenter?.appSecret() ?? ""
    logURLLabel?.stringValue = mobileCenter?.logUrl() ?? ""
    setEnabledButton?.state = (mobileCenter?.isMobileCenterEnabled() ?? false) ? 1 : 0
  }
}
