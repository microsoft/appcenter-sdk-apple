import UIKit
import MobileCenter
import MobileCenterAnalytics

class SasquatchTVViewController: UIViewController {

  @IBOutlet weak var trackEvent: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func trackEventClicked(_ sender: UIButton) {
    MSAnalytics.trackEvent("HelloWorld")
  }
}

