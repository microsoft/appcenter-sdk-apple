import Cocoa

class SasquatchMacViewController: NSTabViewController, MobileCenterProtocol {

  var mobileCenter: MobileCenterDelegate? {
    didSet {
      for tabViewItem in tabViewItems {
        if let view : MobileCenterProtocol = tabViewItem.viewController as? MobileCenterProtocol {
          view.mobileCenter = mobileCenter
        }
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }
}

