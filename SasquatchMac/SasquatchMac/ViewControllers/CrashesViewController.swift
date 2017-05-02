import Cocoa
import MobileCenterCrashesMac

class CrashesViewController : NSViewController {

  @IBOutlet var setEnabledButton : NSButton?;
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setEnabledButton?.state = MSCrashes.isEnabled() ? 1 : 0
  }

  @IBAction func stackOverflowCrash(_ : Any) {
    stackOverflowCrash(self)
  }

  @IBAction func setEnabled(sender : NSButton) {
    MSCrashes.setEnabled(sender.state == 1)
    sender.state = MSCrashes.isEnabled() ? 1 : 0
  }
}
