import Foundation
import UIKit

class EventFilterViewController : UIViewController, AppCenterProtocol {

  var appCenter: AppCenterDelegate!

  @IBOutlet weak var enabledControl: UISegmentedControl!

  @IBAction func setEnabled(_ sender: UISegmentedControl) {
    appCenter.setEventFilterEnabled(sender.selectedSegmentIndex == 0)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    appCenter.startEventFilterService()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    enabledControl.selectedSegmentIndex = appCenter.isEventFilterEnabled() ? 0 : 1
  }
}
