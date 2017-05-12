import Cocoa

class CrashesViewController : NSViewController, MobileCenterProtocol {

  var mobileCenter: MobileCenterDelegate? {
    didSet {
      if let `mobileCenter` = mobileCenter {
        setEnabledButton?.state = mobileCenter.isCrashesEnabled() ? 1 : 0
      }
    }
  }

  @IBOutlet var setEnabledButton : NSButton?;
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if let `mobileCenter` = mobileCenter {
      setEnabledButton?.state = mobileCenter.isCrashesEnabled() ? 1 : 0
    } else {
      setEnabledButton?.state = ServiceStateStore.CrashesState ? 1 : 0
    }
  }

  @IBAction func stackOverflowCrash(_ : Any) {
    if let `mobileCenter` = mobileCenter {
      mobileCenter.generateTestCrash()
    }
  }

  @IBAction func setEnabled(sender : NSButton) {
    guard let `mobileCenter` = mobileCenter else {
      return
    }
    ServiceStateStore.CrashesState = sender.state == 1
    mobileCenter.setCrashesEnabled(sender.state == 1)
    sender.state = mobileCenter.isCrashesEnabled() ? 1 : 0
  }
}
