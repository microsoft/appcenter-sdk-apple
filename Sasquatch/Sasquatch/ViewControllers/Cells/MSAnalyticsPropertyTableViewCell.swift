import UIKit

@objc(MSAnalyticsPropertyTableViewCell) class MSAnalyticsPropertyTableViewCell: UITableViewCell {
  @IBOutlet weak var keyField: UITextField!
  @IBOutlet weak var valueField: UITextField!

  @IBAction func dismissKeyboard(_ sender: UITextField!) {
    sender.resignFirstResponder()
  }
}
