import UIKit

extension UITableViewCell {
  func getSubview<T: UIView>(withTag tag:Int = 0) -> T? {
    for subview in self.contentView.subviews {
      if  (subview.tag == tag) && (subview is T) {
        return subview as? T
      }
    }
    return nil
  }
}
