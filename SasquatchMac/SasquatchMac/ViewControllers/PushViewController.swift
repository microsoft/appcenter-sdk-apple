import Cocoa

class PushViewController: NSViewController {

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!

  @IBOutlet weak var setEnabledButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad();
  }

  override func viewWillAppear() {
    setEnabledButton?.state = appCenter.isPushEnabled() ? 1 : 0
  }
  
  @IBAction func setEnabled(_ sender: NSButton) {
    appCenter.setPushEnabled(sender.state == 1)
    sender.state = appCenter.isPushEnabled() ? 1 : 0
  }
}
