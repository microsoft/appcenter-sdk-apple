import Cocoa

class PushViewController: NSViewController {

  var mobileCenter: MobileCenterDelegate = MobileCenterProvider.shared().mobileCenter!

  @IBOutlet weak var setEnabledButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad();
  }

  override func viewWillAppear() {
    setEnabledButton?.state = mobileCenter.isPushEnabled() ? 1 : 0
  }
  
  @IBAction func setEnabled(_ sender: NSButton) {
    mobileCenter.setPushEnabled(sender.state == 1)
    sender.state = mobileCenter.isPushEnabled() ? 1 : 0
  }
}
