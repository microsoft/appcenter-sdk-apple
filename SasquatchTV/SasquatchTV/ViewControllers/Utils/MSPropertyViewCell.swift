import Foundation
import UIKit

class MSPropertyViewCell : UITableViewCell {

  static let identifier : String = "propertyCell";

  @IBOutlet weak var propertyKey : UITextField?;
  @IBOutlet weak var propertyValue : UITextField?;
}
