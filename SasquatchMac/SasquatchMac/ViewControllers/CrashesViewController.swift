import Cocoa

class CrashesViewController : NSViewController {

  var mobileCenter: MobileCenterDelegate?
  @IBOutlet var setEnabledButton : NSButton?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    mobileCenter = MobileCenterProvider.shared().mobileCenter
    setEnabledButton?.state = mobileCenter!.isCrashesEnabled() ? 1 : 0
  }

  @IBAction func stackOverflowCrash(_ : Any) {
    mobileCenter?.generateTestCrash()
  }

  @IBAction func setEnabled(sender : NSButton) {
    mobileCenter?.setCrashesEnabled(sender.state == 1)
    sender.state = mobileCenter!.isCrashesEnabled() ? 1 : 0
  }
}
